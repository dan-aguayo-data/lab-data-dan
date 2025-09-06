{% macro grant_permission_to_schema(schemas, roles, branch_name) %}
{%- if feature_branch(branch_name)  and target.name not in ["local"] -%}
  {% for schema in schemas %}
    {% for role in roles %}
      {%- if "_BRAZE" in schema -%}
      {%- elif "_ZENDESK" in schema -%}
      {%- elif "DWH_VICRETURN" in schema -%}
      {%- elif "DWH_API" in schema -%}
      {%- elif "TEST" in schema -%}
      {%- else -%}    
        GRANT ALL ON schema {{ schema }} TO ROLE {{ role }};
        GRANT ALL ON ALL TABLES IN schema {{ schema }} TO ROLE {{ role }};
        GRANT ALL ON ALL VIEWS IN schema {{ schema }} TO ROLE {{ role }};
      {%- endif -%}      
    {% endfor %}
  {% endfor %}
{%- endif -%}
{% endmacro %}
