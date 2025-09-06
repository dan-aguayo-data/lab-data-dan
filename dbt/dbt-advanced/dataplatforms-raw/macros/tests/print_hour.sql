{% macro get_warehouse_test(overnight_wh, day_wh) %}
    {% set result = run_query("SELECT EXTRACT(HOUR FROM CONVERT_TIMEZONE('UTC', 'Australia/Sydney', SYSDATE()))::INTEGER") %}
    
    {% if result and result.columns[0].values() %}
        {% set current_hour = result.columns[0].values()[0] %}
    {% else %}
        {% set current_hour = 'UNKNOWN' %}
    {% endif %}

    {% if current_hour != 'UNKNOWN' %}
        {% if current_hour >= 23 or current_hour < 10 %}
            {% set selected_wh = overnight_wh %}
        {% else %}
            {% set selected_wh = day_wh %}
        {% endif %}
    {% else %}
        {% set selected_wh = 'ERROR_DETERMINING_WAREHOUSE' %}
    {% endif %}

    {{ log("Current Hour (Sydney Time): " ~ current_hour, info=True) }}
    {{ log("Selected Warehouse: " ~ selected_wh, info=True) }}

    {{ return(selected_wh) }}
{% endmacro %}
--dbt run-operation get_warehouse --args '{"overnight_wh": "ETL_MARTS_MEDIUM", "day_wh": "ETL_MARTS"}'
