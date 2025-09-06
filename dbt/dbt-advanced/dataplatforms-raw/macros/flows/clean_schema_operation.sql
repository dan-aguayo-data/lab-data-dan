{% macro clean_schema_ops(branch_name, dry_run=false) %}
{#
  Finds schemas with names that correspond to the git branch and drops them - unless dry_run is specified.
  Intended for usage in the TEST database environment for clean up, but can also be used in DEV.

  Usage:
  dry run ( only print drop statements )
    dbt run-operation clean_schema_ops --target dev --args "{branch_name: $(git branch --show-current) , dry_run: true}"

  normal run ( executes drop statements )
    dbt run-operation clean_schema_ops --target dev --args "{branch_name: $(git branch --show-current)}"
#}
  {%- if feature_branch(branch_name) -%}

    {% set sql %}
    {%- for stage in var('data_stages') %}
        DROP SCHEMA IF EXISTS {{ resolve_schema_name(stage, branch_name) }};
    {%- endfor -%}
    {% endset %}

    {% do log(sql, info=True) %}

    {%- if sql|length -%}
      {%- if dry_run -%}
        {% do log('Dry run, not dropping anything.', info=True)%}
      {%- else -%}
        {% do run_query(sql) %}
        {% do log('Done.', info=True) %}
      {%- endif -%}
    {%- else -%}
      {% do log('No Schemas to drop..', info=True) %}
    {%- endif -%}


  {%- else -%}
    {% do log("Running at " ~ branch_name ~ ", skip  dropping schemas", info=True) %}

  {%- endif -%}
{% endmacro %}
