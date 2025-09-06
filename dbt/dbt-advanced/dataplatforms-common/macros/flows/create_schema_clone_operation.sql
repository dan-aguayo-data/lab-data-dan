{% macro create_schema_clone_ops(branch_name) %}
  {%- if feature_branch(branch_name) -%}

    {% set sql %}
      {%- for stage in var('data_stages') -%}
        {%- set schema_stem = resolve_schema_stem(stage) -%}
        {%- set schema_name = resolve_schema_name(stage, branch_name) -%}
        {%- set db_name = var('src_clone_db') -%}

        {%- if schema_exists(db_name, schema_stem) -%}
        CREATE SCHEMA IF NOT EXISTS {{ schema_name }} CLONE {{ db_name }}.{{ schema_stem }};

        {%- endif -%}
      {%- endfor -%}
    {% endset %}

    {% do log(sql, info=True) %}

    {%- if sql|length -%}
      {% do run_query(sql) %}
      {% do log('Done.', info=True) %}
    {%- else -%}
      {% do log('No Clone SQL to RUN..', info=True) %}
    {%- endif -%}


  {%- else -%}
    {% do log("Running at " ~ branch_name ~ ", skip creating clones", info=True) %}

  {%- endif -%}
{% endmacro %}
