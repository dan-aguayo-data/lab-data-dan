{% macro grant_permission_to_schema(schemas, role, branch_name) %}
{%- if feature_branch(branch_name) and target.name not in ["local", "dev"] -%}
  {% for schema in schemas %}
  {{ log(schema , info=True) }}
    {%- if "_PROD" in schema -%}
    {%- elif "_FULL_LOAD" in schema -%}
    {%- elif "_INCREMENTALS" in schema -%}
    {%- elif "_DEV" in schema -%}
    {%- elif "_STG" in schema -%}
    {%- else -%}
      GRANT ALL ON schema {{ schema }} TO ROLE {{ role }};
      GRANT ALL ON ALL TABLES IN schema {{ schema }} TO ROLE {{ role }};
      GRANT ALL ON ALL VIEWS IN schema {{ schema }} TO ROLE {{ role }};
    {%- endif -%}
  {% endfor %}
{%- endif -%}
{% endmacro %}
