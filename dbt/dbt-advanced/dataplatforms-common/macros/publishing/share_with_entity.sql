{% macro share_with_entity(entities) %}

    {%- for entity_var in entities -%}

        {% set ref_query %}
            SELECT * FROM "CES_REF"."CES_REFERENCE"."ENTITY_SHARE" WHERE ENTITY = '{{ entity_var }}'
        {% endset %}

        {# run_query returns agate.Table (https://agate.readthedocs.io/en/1.6.1/api/table.html). #}
        {% set ref_results = run_query(ref_query) %}

        {% if execute %}
            {% set ref_results_list = ref_results.rows %}
        {% else %}
            {% set ref_results_list = [] %}
        {% endif %}

            {% set sql %}
                {%- for item in ref_results_list -%}                
                    CREATE OR REPLACE VIEW {{ item['TGT_DATABASE'] }}.{{ item['TGT_SCHEMA'] }}.{{ item['TGT_TABLE'] }} as (
                        SELECT 
                        {% if item['TBL_COLUMNS'] is not none %} {{ item['TBL_COLUMNS'] }} {% else %} * {% endif %}
                        FROM {{ item['SRC_DATABASE'] }}.{{ item['SRC_SCHEMA'] }}.{{ item['SRC_TABLE'] }}
                        WHERE (1 = 1) 
                        {% if item['MULTI_SCHEME_ID'] != '0' -%}
                        AND multi_scheme_id IN ({{ item['MULTI_SCHEME_ID'] }}) 
                        {%- endif -%}
                        {% if item['OTHER_CLAUSE'] is not none %}
                        AND {{ item['OTHER_CLAUSE'] }}
                        {%- endif -%}
                    );
 
                    {% if item['OBJ_ROLE'] is not none %}

                        {% set obj_role_array = item['OBJ_ROLE'].split(',') %}

                        {% for obj_item_role in obj_role_array %} 
                            GRANT SELECT ON VIEW {{ item['TGT_DATABASE'] }}.{{ item['TGT_SCHEMA'] }}.{{ item['TGT_TABLE'] }} TO {{ obj_item_role|upper|trim }};
                        {% endfor %}

                    {%- endif -%}                    

                {%- endfor -%}
            {% endset %}

            {%- if sql|length -%}
                {% do run_query(sql) %}
                {% do log('Done.', info=True) %}
            {%- else -%}
                {% do log('No views to create...', info=True) %}
            {%- endif -%}

    {%- endfor -%}        

{% endmacro %}
