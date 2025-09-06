--not working because the macro has to be parsed as a variable at run time, not doing that because it will add time to all model runs

{% macro run_flag_only_day01() %}
  {% set current_datetime = run_started_at.astimezone(modules.pytz.timezone('Australia/Sydney')) %}
  {% set current_day = current_datetime.strftime('%d') | int %}

  {% if current_day == 1 %}
    {% do return(True) %}
  {% else %}
    {% do return(False) %}
  {% endif %}
{% endmacro %}