{% macro generate_schema_name(custom_schema_name, node) -%}
{# This macro overrides a system macro - its name is special and should not be changed #}

    {{ resolve_schema_name(custom_schema_name, var('branch')) }}

{%- endmacro %}
