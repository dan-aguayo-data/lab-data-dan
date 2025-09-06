{% macro get_warehouse(overnight_wh, day_wh) %}
    {% set current_hour = run_query("SELECT EXTRACT(HOUR FROM CONVERT_TIMEZONE('UTC', 'Australia/Sydney', SYSDATE()))::INTEGER").columns[0].values()[0] %}

    {% if current_hour >= 23 or current_hour < 3 %}
        {{ return(overnight_wh) }}
    {% else %}
        {{ return(day_wh) }}
    {% endif %}
{% endmacro %}
