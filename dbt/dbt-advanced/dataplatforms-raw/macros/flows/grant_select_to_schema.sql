{% macro grant_select_to_schema(schemas, roles, branch_name) %}
{%- if feature_branch(branch_name)  and target.name not in ["local"] -%}
  {% for schema in schemas %}
    {% for role in roles %}
      {%- if "_PROD" in schema -%}
      {%- elif "_FULL_LOAD" in schema -%}
      {%- elif "_INCREMENTALS" in schema -%}
      {%- elif "_DEV" in schema -%}
      {%- elif "_STG" in schema -%}
      {%- else -%}
        GRANT USAGE ON schema {{ schema }} TO ROLE {{ role }};
        GRANT SELECT ON ALL TABLES IN schema {{ schema }} TO ROLE {{ role }};
        GRANT SELECT ON ALL VIEWS IN schema {{ schema }} TO ROLE {{ role }};
      {%- endif -%}
    {% endfor %}
  {% endfor %}
{%- endif -%}
{% endmacro %}
