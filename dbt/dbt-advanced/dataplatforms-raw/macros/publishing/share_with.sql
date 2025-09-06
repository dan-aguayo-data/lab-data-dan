{% macro share_with_subsidiaries(subsidiaries) %}

  {%- for item in subsidiaries -%}
    {% set schema_name = item.split(':')[0] %}
    {% set second_part = item.split(':')[1] %}
    {% if second_part == "coex" %}
      {% set businesses = ["COEX"] %}
    {% elif second_part == "both" %}
      {% set businesses = ["COEX","WARRRL"] %}
    {% else %}
      {% set businesses = 0 %}
      {% do log('No matching case', info=True) %}
    {% endif %}

    {%- for business in businesses -%}
      {% if business == "COEX" %}
        {% set multi_scheme_id = 10000 %}
      {% elif business == "WARRRL" %}
        {% set multi_scheme_id = 10001 %}
      {% else %}
        {% set multi_scheme_id = 0 %}
        {% do log('No matching case', info=True) %}
      {% endif %}

      {{ log("multi_scheme_id: " ~ multi_scheme_id, True) }}

      {% set has_msi_query %}
        SELECT table_name,
        sum(case when column_name = 'MULTI_SCHEME_ID' then 1 else 0 end) as has_msi
        FROM {{ target.database|upper }}."INFORMATION_SCHEMA"."COLUMNS"
        WHERE table_schema = '{{schema_name}}'
        and table_name in (
          SELECT table_name
          FROM {{ target.database|upper }}."INFORMATION_SCHEMA"."TABLES"
          where last_altered >= dateadd(hours, -2, current_timestamp())
          UNION
          SELECT table_name
          FROM {{ target.database|upper }}."INFORMATION_SCHEMA"."VIEWS"
          where last_altered >= dateadd(hours, -2, current_timestamp())
        )
        group by 1
        HAVING HAS_MSI > 0
      {% endset %}

      {# run_query returns agate.Table (https://agate.readthedocs.io/en/1.6.1/api/table.html). #}
      {% set has_msi_results = run_query(has_msi_query) %}

      {% if execute %}
        {% set has_msi_list_of_tables = has_msi_results.columns['TABLE_NAME'] %} 
        {{ create_msi_view('has_msi', has_msi_list_of_tables, multi_scheme_id, business, schema_name) }}
      {% else %}
        {% set has_msi_list_of_tables = [] %}
      {% endif %}
      {{ log("tables shared with msi column: " ~ has_msi_list_of_tables, True) }}


      {% set no_msi_query %}
        SELECT table_name,
        sum(case when column_name = 'MULTI_SCHEME_ID' then 1 else 0 end) as has_msi
        FROM {{ target.database|upper }}."INFORMATION_SCHEMA"."COLUMNS"
        WHERE table_schema = '{{schema_name}}'
        and table_name in (
          SELECT table_name
          FROM {{ target.database|upper }}."INFORMATION_SCHEMA"."TABLES"
          where last_altered >= dateadd(hours, -2, current_timestamp())
          UNION
          SELECT table_name
          FROM {{ target.database|upper }}."INFORMATION_SCHEMA"."VIEWS"
          where last_altered >= dateadd(hours, -2, current_timestamp())
        )
        group by 1
        HAVING HAS_MSI = 0
      {% endset %}

      {# run_query returns agate.Table (https://agate.readthedocs.io/en/1.6.1/api/table.html). #}
      {% set no_msi_results = run_query(no_msi_query) %}

      {% if execute %}
        {% set no_msi_list_of_tables = no_msi_results.columns['TABLE_NAME'] %} 
        {{ create_msi_view('no_msi', no_msi_list_of_tables, multi_scheme_id, business, schema_name) }}
      {% else %}
        {% set no_msi_list_of_tables = [] %}
      {% endif %}
      {{ log("tables shared without msi column: " ~ no_msi_list_of_tables, True) }}

    {%- endfor -%}
    
  {%- endfor -%}

{% endmacro %}
