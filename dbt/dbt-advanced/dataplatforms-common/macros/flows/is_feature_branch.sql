{% macro feature_branch(branch_name) %}
  {%- if branch_name is none or branch_name in var('no_schema_update_branches') -%}
    {{ return(false) }}
  {%- else -%}
    {{ return(true) }}
  {%- endif -%}
{% endmacro %}
