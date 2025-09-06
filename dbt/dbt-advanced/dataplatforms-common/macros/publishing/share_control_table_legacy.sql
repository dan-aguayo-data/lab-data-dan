{% macro share_with_control_table_manual_legacy(entities,databases,schemas) %}

{% set entity_check = entities[0] %} 
{% set database_check = databases[0] %} 
{% set schema_check = schemas[0] %} 
{% set environment_name = target.name %}

{% if entity_check == "*"  %}
    {{ log("GETTING LIST OF ENTITIES FROM REFERENCE TABLE ENTITY_MULTI_SCHEME_ID_REF...." , info=True) }}
    {% set ref_entity_sql %}
        SELECT DISTINCT ENTITY_NAME FROM
        "CES_REF"."CES_DBT"."ENTITY_MULTI_SCHEME_ID_REF"
        WHERE UPPER(DBT_PROJECT) = 'RAW';
    {% endset %}
    {% set ref_entity_results = run_query(ref_entity_sql) %}
    {% if execute %}
        {% set ref_entity_results_list = ref_entity_results.rows %}
    {% else %}
        {% set ref_entity_results_list = [] %}
    {% endif %}
        {%- for item in ref_entity_results_list -%}
            {% set entity_name = item['ENTITY_NAME'] %}
            {% if database_check == "*"  %}
                {{ log("GETTING LIST OF DATABASES FROM CRONTOL TABLE FOR ENTITY: " ~ entity_name , info=True) }}
                {% set control_databases_sql %}
                    SELECT DISTINCT SOURCE_DATABASE FROM
                    "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                    WHERE DBT_PROJECT = 'RAW' AND TARGET_ENTITY_NAME = '{{entity_name}}' AND SOURCE_ENVIRONMENT = '{{environment_name}}'  ;
                {% endset %}
                {% set control_databases_results = run_query(control_databases_sql) %}
                {% if execute %}
                    {% set control_databases_results_list = control_databases_results.rows %}
                {% else %}
                    {% set control_databases_results_list = [] %}
                {% endif %}
                {% if control_databases_results_list == "" %}
                {% set control_databases_results_list = ["1"] %}
                {% endif %}
            {% set database_list = control_databases_results_list %}
            {% set db_list_type = 'table' %}
            {% else %}
            {% set database_list = databases %}
            {% set db_list_type = 'list' %}
            {% endif %}  
            {% for database in database_list %}
            {% if db_list_type == 'list' %}
            {% set database_name = database %}
            {% else %}
            {% set database_name =  database['SOURCE_DATABASE'] %}
            {% endif %}
                {% if schema_check == "*"  %}
                {{ log("GETTING LIST OF SCHEMAS FROM DATABASE: " ~ database_name , info=True) }}
                {% set control_schemas_sql %}
                    SELECT DISTINCT SOURCE_SCHEMA FROM
                    "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                    WHERE DBT_PROJECT = 'RAW' AND TARGET_ENTITY_NAME = '{{entity_name}}' AND SOURCE_ENVIRONMENT = '{{environment_name}}' AND SOURCE_DATABASE = '{{database_name}}'  ;
                {% endset %}
                {% set control_schemas_results = run_query(control_schemas_sql) %}
                {% if execute %}
                    {% set control_schemas_results_list = control_schemas_results.rows %}
                {% else %}
                    {% set control_schemas_results_list = [] %}
                {% endif %}
                {% if control_schemas_results_list == "" %}
                {% set control_schemas_results_list = ["1"] %}
                {% endif %}
                {% set schema_list = control_schemas_results_list %}
                {% set schema_list_type = 'table' %}
                {% else %}
                {% set schema_list = schemas %}
                {% set schema_list_type = 'list' %}
                {% endif %}
                {% for schema in schema_list %}
                {% if schema_list_type == 'list' %}
                {% set schema_name = schema %}
                {% else %}
                {% set schema_name =  schema['SOURCE_SCHEMA'] %}
                {% endif %}
                    {{ log("ASSESSING IF SHARE ON " ~ database_name ~ "." ~ schema_name ~ " FOR " ~entity_name, info=True) }}
                    {% set flag_query %}
                        SELECT 
                        SUM(DB_SHCEMA_FLAG) AS DB_SCHEMA_FLAG
                        FROM(
                        SELECT DISTINCT
                        CASE WHEN (SOURCE_DATABASE || '.' || SOURCE_SCHEMA) IS NULL THEN 0 ELSE 1 END AS DB_SHCEMA_FLAG 
                        FROM
                        "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                        WHERE SOURCE_DATABASE = '{{database_name}}' AND SOURCE_SCHEMA = '{{schema_name}}' AND TARGET_ENTITY_NAME = '{{entity_name}}'  AND SOURCE_ENVIRONMENT = '{{environment_name}}'  AND DBT_PROJECT = 'RAW'
                        UNION
                        SELECT 
                        0 AS DB_SHCEMA_FLAG ) X;
                    {% endset %}
                    {% set flag_query_results = run_query(flag_query) %}
                    {% if execute %}
                        {% set flag_output = flag_query_results.columns[0].values()[0] %}
                    {% else %}
                        {% set flag_output = None %}
                    {% endif %}
                    {%- if flag_output == 1 %}
                        {% set control_sql %}
                            SELECT * FROM
                            "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                            WHERE SOURCE_DATABASE = '{{database_name}}' AND SOURCE_SCHEMA = '{{schema_name}}' AND DBT_PROJECT = 'RAW' AND TARGET_ENTITY_NAME = '{{entity_name}}' ;
                        {% endset %}
                        {% set control_results = run_query(control_sql) %}
                        {% if execute %}
                            {% set control_results_list = control_results.rows %}
                        {% else %}
                            {% set control_results_list = [] %}
                        {% endif %}
                        {% set share_query %}
                            {%- for item in control_results_list -%}
                                {% set TGT_SCHEME =  item['TARGET_ENTITY_NAME'] %}
                                {% set TGT_DATABASE =  item['TARGET_DATABASE'] %}
                                {% set TGT_SCHEMA =  item['TARGET_SCHEMA'] %}
                                {% set TGT_TABLE =  item['TARGET_TABLE'] %}
                                {{ log("Generating share for Entity: " ~TGT_SCHEME ~ " on object: " ~ TGT_DATABASE ~ "." ~ TGT_SCHEMA  ~ "."  ~ TGT_TABLE, info=True) }}
                                CREATE OR REPLACE VIEW {{ item['TARGET_DATABASE'] }}.{{ item['TARGET_SCHEMA'] }}.{{ item['TARGET_TABLE'] }} as (
                                SELECT 
                                {% if item['COLUMNS_TO_SHARE'] is not none %}
                                    {{ item['COLUMNS_TO_SHARE'] }}
                                {% else %}
                                    *
                                {% endif %}
                                FROM {{ item['SOURCE_DATABASE'] }}.{{ item['SOURCE_SCHEMA'] }}.{{ item['SOURCE_TABLE'] }}
                                WHERE 1 = 1
                                {% if item['HAS_MSI_FILTER'] != 'NO' %}
                                AND (multi_scheme_id IN ({{ item['MULTISCHEME_ID'] }}) or multi_scheme_id is null)
                                {% endif %}
                                {% if item['OTHER_FILTERS'] is not none %}
                                AND {{ item['OTHER_FILTERS'] }}
                                {% endif %}
                                );
                                {%- set target_roles = item['TARGET_ROLES'].split(',') -%}
                                {%- for role in target_roles -%}
                                GRANT SELECT ON VIEW {{ TGT_DATABASE }}.{{ TGT_SCHEMA }}.{{ TGT_TABLE }} TO {{ role.strip() }}
                                ;
                                {%- endfor -%}
                            {%- endfor -%}
                        {% endset %}
                                {{ log("Query to execute for " ~ entity_name ~" on "~ database_name ~ "." ~ schema_name ~ ": " ~ share_query, info=True) }}
                                {% do run_query(share_query) %}
                                {% do log('Query executed.', info=True) %}
                    {%- else %}
                        {{ log("No Views or Schema Shares to create for: " ~entity_name  , info=True) }}
                    {%- endif %}         
                {% endfor %}  --for schema     
            {% endfor %}  --for database
        {% endfor %}  --for entity

{% else %} 

        {% for entity in entities %}  
            {% set entity_name = entity %}
            {% if database_check == "*"  %}
                {{ log("GETTING LIST OF DATABASES FROM CRONTOL TABLE FOR ENTITY: " ~ entity_name , info=True) }}
                {% set control_databases_sql %}
                    SELECT DISTINCT SOURCE_DATABASE FROM
                    "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                    WHERE DBT_PROJECT = 'RAW' AND TARGET_ENTITY_NAME = '{{entity_name}}' AND SOURCE_ENVIRONMENT = '{{environment_name}}'  ;
                {% endset %}
                {% set control_databases_results = run_query(control_databases_sql) %}
                {% if execute %}
                    {% set control_databases_results_list = control_databases_results.rows %}
                {% else %}
                    {% set control_databases_results_list = [] %}
                {% endif %}
                {% if control_databases_results_list == "" %}
                {% set control_databases_results_list = ["1"] %}
                {% endif %}
            {% set database_list = control_databases_results_list %}
            {% set db_list_type = 'table' %}
            {% else %}
            {% set database_list = databases %}
            {% set db_list_type = 'list' %}
            {% endif %}  
            {% for database in database_list %}
            {% if db_list_type == 'list' %}
            {% set database_name = database %}
            {% else %}
            {% set database_name =  database['SOURCE_DATABASE'] %}
            {% endif %}
                {% if schema_check == "*"  %}
                {{ log("GETTING LIST OF SCHEMAS FROM DATABASE: " ~ database_name , info=True) }}
                {% set control_schemas_sql %}
                    SELECT DISTINCT SOURCE_SCHEMA FROM
                    "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                    WHERE DBT_PROJECT = 'RAW' AND TARGET_ENTITY_NAME = '{{entity_name}}' AND SOURCE_ENVIRONMENT = '{{environment_name}}' AND SOURCE_DATABASE = '{{database_name}}'  ;
                {% endset %}
                {% set control_schemas_results = run_query(control_schemas_sql) %}
                {% if execute %}
                    {% set control_schemas_results_list = control_schemas_results.rows %}
                {% else %}
                    {% set control_schemas_results_list = [] %}
                {% endif %}
                {% if control_schemas_results_list == "" %}
                {% set control_schemas_results_list = ["1"] %}
                {% endif %}
                {% set schema_list = control_schemas_results_list %}
                {% set schema_list_type = 'table' %}
                {% else %}
                {% set schema_list = schemas %}
                {% set schema_list_type = 'list' %}
                {% endif %}
                {% for schema in schema_list %}
                {% if schema_list_type == 'list' %}
                {% set schema_name = schema %}
                {% else %}
                {% set schema_name =  schema['SOURCE_SCHEMA'] %}
                {% endif %}
                    {{ log("ASSESSING IF SHARE ON " ~ database_name ~ "." ~ schema_name ~ " FOR " ~entity_name, info=True) }}
                    {% set flag_query %}
                        SELECT 
                        SUM(DB_SHCEMA_FLAG) AS DB_SCHEMA_FLAG
                        FROM(
                        SELECT DISTINCT
                        CASE WHEN (SOURCE_DATABASE || '.' || SOURCE_SCHEMA) IS NULL THEN 0 ELSE 1 END AS DB_SHCEMA_FLAG 
                        FROM
                        "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                        WHERE SOURCE_DATABASE = '{{database_name}}' AND SOURCE_SCHEMA = '{{schema_name}}' AND TARGET_ENTITY_NAME = '{{entity_name}}'  AND SOURCE_ENVIRONMENT = '{{environment_name}}'  AND DBT_PROJECT = 'RAW'
                        UNION
                        SELECT 
                        0 AS DB_SHCEMA_FLAG ) X;
                    {% endset %}
                    {% set flag_query_results = run_query(flag_query) %}
                    {% if execute %}
                        {% set flag_output = flag_query_results.columns[0].values()[0] %}
                    {% else %}
                        {% set flag_output = None %}
                    {% endif %}
                    {%- if flag_output == 1 %}
                        {% set control_sql %}
                            SELECT * FROM
                            "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
                            WHERE SOURCE_DATABASE = '{{database_name}}' AND TARGET_ENTITY_NAME = '{{entity_name}}' AND SOURCE_SCHEMA = '{{schema_name}}' AND DBT_PROJECT = 'RAW' ;
                        {% endset %}
                        {% set control_results = run_query(control_sql) %}
                        {% if execute %}
                            {% set control_results_list = control_results.rows %}
                        {% else %}
                            {% set control_results_list = [] %}
                        {% endif %}
                        {% set share_query %}
                            {%- for item in control_results_list -%}
                                {% set TGT_SCHEME =  item['TARGET_ENTITY_NAME'] %}
                                {% set TGT_DATABASE =  item['TARGET_DATABASE'] %}
                                {% set TGT_SCHEMA =  item['TARGET_SCHEMA'] %}
                                {% set TGT_TABLE =  item['TARGET_TABLE'] %}
                                {{ log("Generating sahre for Entity: " ~TGT_SCHEME ~ " on object: " ~ TGT_DATABASE ~ "." ~ TGT_SCHEMA  ~ "."  ~ TGT_TABLE, info=True) }}
                                CREATE OR REPLACE VIEW {{ item['TARGET_DATABASE'] }}.{{ item['TARGET_SCHEMA'] }}.{{ item['TARGET_TABLE'] }} as (
                                SELECT 
                                {% if item['COLUMNS_TO_SHARE'] is not none %}
                                    {{ item['COLUMNS_TO_SHARE'] }}
                                {% else %}
                                    *
                                {% endif %}
                                FROM {{ item['SOURCE_DATABASE'] }}.{{ item['SOURCE_SCHEMA'] }}.{{ item['SOURCE_TABLE'] }}
                                WHERE 1 = 1
                                {% if item['HAS_MSI_FILTER'] != 'NO' %}
                                AND (multi_scheme_id IN ({{ item['MULTISCHEME_ID'] }}) or multi_scheme_id is null)
                                {% endif %}
                                {% if item['OTHER_FILTERS'] is not none %}
                                AND {{ item['OTHER_FILTERS'] }}
                                {% endif %}
                                );
                                {%- set target_roles = item['TARGET_ROLES'].split(',') -%}
                                {%- for role in target_roles -%}
                                GRANT SELECT ON VIEW {{ TGT_DATABASE }}.{{ TGT_SCHEMA }}.{{ TGT_TABLE }} TO {{ role.strip() }}
                                ;
                                {%- endfor -%}
                            {%- endfor -%}
                        {% endset %}
                                {{ log("Query to execute for " ~ entity_name ~" on "~ database_name ~ "." ~ schema_name ~ ": " ~ share_query, info=True) }}
                                {% do run_query(share_query) %}
                                {% do log('Query executed.', info=True) %}
                    {%- else %}
                        {{ log("No Views or Schema Shares to create for: " ~entity_name  , info=True) }}
                    {%- endif %}         
                {% endfor %}  --for schema     
            {% endfor %}  --for database
        {% endfor %}   --FOR ENTITY
        {{ log("END OF MACRO. "  , info=True) }}
{% endif %} 
{% endmacro %}
