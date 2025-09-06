{% macro create_msi_view(msi, table_names, multi_scheme_id, business, schema_name) %}

  {% set dbname = target.database|upper %}
  {% do log("dbname: " ~ dbname, info=True) %}
  {% set dbpart = dbname.split('_') %}

  {% set sql %}
    {%- for table_name in table_names -%}  {% if msi == "has_msi" %}
        CREATE OR REPLACE VIEW {{business}}_{{dbpart[1]}}.{{schema_name}}.{{table_name}} as (
          SELECT *
          FROM {{ target.database|upper }}.{{schema_name}}.{{table_name}}
          where multi_scheme_id = {{multi_scheme_id}}
          or multi_scheme_id is null
        );
        GRANT SELECT ON VIEW {{business}}_{{dbpart[1]}}.{{schema_name}}.{{table_name}} TO SF_DEV_{{business}}  ;
      {% elif msi == "no_msi" %}
        CREATE OR REPLACE VIEW {{business}}_{{dbpart[1]}}.{{schema_name}}.{{table_name}} as (
          SELECT *
          FROM {{ target.database|upper }}.{{schema_name}}.{{table_name}}
        );
        GRANT SELECT ON VIEW {{business}}_{{dbpart[1]}}.{{schema_name}}.{{table_name}} TO SF_DEV_{{business}}  ;
      {% else %}
        {% do log('No matching case', info=True) %}
      {% endif %}
    {%- endfor -%}
  {% endset %}

  {%- if sql|length -%}
      {% do run_query(sql) %}
      {% do log('Done.', info=True) %}
  {%- else -%}
    {% do log('No views to create...', info=True) %}
  {%- endif -%}

{% endmacro %}
