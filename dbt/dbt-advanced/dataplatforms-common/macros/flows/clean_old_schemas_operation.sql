{% macro clean_old_schemas_ops(branch_name, dry_run=false, age_in_days=7) %}
{#
  Finds schemas that are older than 7 days or some other "age_in_days" parameter value.
  Filters to the database as specified in profiles.yml for the current target e.g. dev or test
  Filters to the schemas based on the schema specified in profiles.yml concatenated to
      each of the values of "data_stages" as specified in dbt_project.yml
  Drops those schemas - unless the "dry_run" parameter value is true

  Usage:
  dry run ( just print drop statements )
    dbt run-operation clean_old_schemas_ops --target dev --args "{branch_name: $(git branch --show-current) , dry_run: true}"

  normal run ( executes drop statements ) use this to delete branches in DEV older than the default "age_in_days".
    dbt run-operation clean_old_schemas_ops --target dev --args "{branch_name: $(git branch --show-current)}"

  wipe all the tables no matter how old - dry run
    dbt run-operation clean_old_schemas_ops --target dev --args "{branch_name: $(git branch --show-current), dry_run: true, age_in_days: 0}"
#}
  {% if feature_branch(branch_name) %}

    {% set get_old_schema_query %}{{ "      " -}}
      select
        concat(sch.catalog_name, '.', sch.schema_name) as schema_to_drop,
        max(coalesce(tbl.last_altered, sch.last_altered))::timestamp(0) as schema_altered
      from information_schema.schemata as sch
      left join information_schema.tables as tbl
          on sch.catalog_name = tbl.table_catalog and sch.schema_name = tbl.table_schema
      where sch.catalog_name = '{{ target.database|upper }}'
          and ( false
    {%- for stage in var('data_stages') %}{{ "\n                " -}}
                or sch.schema_name like '{{ resolve_schema_stem(stage)|upper }}%'
    {%- endfor -%}
    {{- "\n      )\n      " -}}
      group by sch.catalog_name, sch.schema_name
      having schema_altered < dateadd(day, -1 * {{ age_in_days }}, current_timestamp());
    {{- "\n" -}}
    {%- endset %}

    {% do log("\nRunning query to find schemas older than " ~ age_in_days ~ " days:\n", info=True) %}
    {% do log(get_old_schema_query, info=true) %}

    {% if execute %}
      {% set old_schema_result = run_query(get_old_schema_query) %}

      {% if dry_run %}
        {% do log('\nDry run, not dropping anything.\n', info=True)%}
      {% endif %}

      {% if not old_schema_result|length %}
        {% do log('\nNo schemas to drop.\n', info=True) %}
      {% endif %}

      {% for row in old_schema_result %}
        {% set schema_to_drop = row[0] %}
        {% set drop_query = "drop schema if exists " ~ schema_to_drop ~ ";" %}
        {% do log(drop_query ~ " /* last modified: " ~ row[1] ~ " UTC */", info=True) %}
        {% if not dry_run %}
          {% do run_query(drop_query) %}
        {% endif %}
      {% endfor %}

    {%- endif -%}

  {%- else -%}
    {% do log("Running at " ~ branch_name ~ ", skip schemas clean up.", info=True) %}
  {%- endif -%}

{% endmacro %}
