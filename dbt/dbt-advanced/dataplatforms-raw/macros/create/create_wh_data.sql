{% macro create_wh_data() %}

    {% set show_warehouses %}
        SHOW WAREHOUSES;
    {% endset %}

    {% do run_query(show_warehouses) %}

    {% set find_query %}
        SET query_id = (
        SELECT QUERY_ID
        FROM TABLE({{ target.name.upper() }}.INFORMATION_SCHEMA.QUERY_HISTORY())
        WHERE QUERY_TEXT = 'SHOW WAREHOUSES;'
        ORDER BY START_TIME DESC
        LIMIT 1
        );
 
    {% endset %}

    {% do run_query(find_query) %}

    {% set create_tbl %}
        CREATE OR REPLACE TABLE CES_REF.CES_REFERENCE.WH_DATA
        AS
        SELECT *
        FROM TABLE(RESULT_SCAN($query_id));

    {% endset %}
        
    {% do run_query(create_tbl) %}


{% endmacro %} 