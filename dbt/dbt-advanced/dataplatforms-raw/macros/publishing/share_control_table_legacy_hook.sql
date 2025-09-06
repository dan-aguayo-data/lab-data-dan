{% macro share_with_control_table(database_schemas) %}
  
    {% for database_schema in database_schemas %}
        {%- set database = database_schema[0] %}
        {%- set schema = database_schema[1] %}
        {%- set fq_schema = database ~ '.' ~ schema %}

        {{ log("ASSESSING IF SHARE IS NEEDED ON " ~ fq_schema, info=True) }}

         {% set flag_query %}
            SELECT 
            SUM(DB_SHCEMA_FLAG) AS DB_SCHEMA_FLAG
            FROM(
            SELECT DISTINCT
            CASE WHEN (SOURCE_DATABASE || '.' || SOURCE_SCHEMA) IS NULL THEN 0 ELSE 1 END AS DB_SHCEMA_FLAG 
            FROM
            "CES_REF"."CES_DBT"."DBT_SHARE_CONTROL"
            WHERE SOURCE_DATABASE = '{{database}}' AND SOURCE_SCHEMA = '{{schema}}' AND DBT_PROJECT = 'RAW'
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
                WHERE SOURCE_DATABASE = '{{database}}' AND SOURCE_SCHEMA = '{{schema}}' AND DBT_PROJECT = 'RAW' ;
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
                        AND multi_scheme_id IN ({{ item['MULTISCHEME_ID'] }})
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
                        {{ log("Query to execute:" ~ share_query, info=True) }}
                        {% do run_query(share_query) %}
                        {% do log('Query executed.', info=True) %}
        {%- else %}
            {{ log("No Views or Schema Shares to create for db.schema: " ~ fq_schema , info=True) }}
        {%- endif %}

    {% endfor %}

{% endmacro %}

