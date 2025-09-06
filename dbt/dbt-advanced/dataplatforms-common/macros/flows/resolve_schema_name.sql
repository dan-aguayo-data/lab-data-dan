{% macro resolve_schema_name(schema_name, branch_name) %}

  {%- set schema_stem = resolve_schema_stem(schema_name) -%}

  {%- if feature_branch(branch_name) -%}

    {%- set schema_suffix = resolve_schema_suffix(branch_name) -%}

    {{ return(schema_stem ~ schema_suffix) }}

  {%- else -%}

    {{ return(schema_stem) }}

  {%- endif -%}
{% endmacro %}


{% macro resolve_schema_stem(schema_name) %}
  {%- if schema_name is none -%}

    {{ return(target.schema) }}

  {%- else -%}

    {{ return(schema_name) }}

  {%- endif -%}
{% endmacro %}


{% macro resolve_schema_suffix(branch_name) %}
  {%- if branch_name and branch_name|length -%}

    {{ return('_' ~ branch_name | trim | replace('-', '_')) }}

  {%- else -%}

    {{ return('') }}

  {%- endif -%}
{% endmacro %}
