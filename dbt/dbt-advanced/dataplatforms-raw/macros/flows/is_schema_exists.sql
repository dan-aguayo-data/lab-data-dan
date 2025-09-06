{% macro schema_exists(db_name, schema_name) %}
  {% set get_src_schema_query %}
    show schemas LIKE '{{ schema_name }}' in {{ db_name }};
  {% endset %}

  {% set src_schema_results = run_query(get_src_schema_query) %}

  {% if execute %}
    {% set results_size = src_schema_results.columns['name'].values()|length %}
  {% else %}
    {% set results_size = 0 %}
  {% endif %}

  {% do log(get_src_schema_query, info=True) %}
  {% do log(results_size, info=True) %}

  {% if results_size > 0 %}
    {{ return(true) }}
  {% else %}
    {{ return(false) }}
  {% endif %}

{% endmacro %}
