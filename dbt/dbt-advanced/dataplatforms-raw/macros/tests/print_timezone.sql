{% macro test_timezone() %}
  {% set current_datetime = run_started_at.astimezone(modules.pytz.timezone('Australia/Sydney')) %}
  {% set current_day = current_datetime.strftime('%d') | int %}
  {{ log("Current DateTime in Australia/Sydney: " ~ current_datetime, info=True) }}
  {{ log("Current DateTime in Australia/Sydney: " ~ current_day, info=True) }}
{% endmacro %}
--dbt run-operation test_timezone

 