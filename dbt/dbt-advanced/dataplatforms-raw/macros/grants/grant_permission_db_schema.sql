{% macro grant_permission_to_db_schema(database_schemas, roles, branch_name, schema_exclusions,db_exclusions) %}
{{ log("Starting granting all permissions macro......", info=True) }}
{%- if feature_branch(branch_name) and target.name not in ["local", "dev"] -%}
  {% for database_schema in database_schemas %}
    {%- set database = database_schema[0] %}
    {%- set schema = database_schema[1] %}
    {%- set fq_schema = database ~ '.' ~ schema %}
    {%- set ns = namespace(exclude=false) %}
    {%- for db_exclusion in db_exclusions %}
      {%- if db_exclusion in database %}
        {{ log("Match with db exclusion list: " ~ database ~ " excluding...", info=True) }}
        {%- set ns.exclude = true %}
        {%- break %}
      {%- endif %}
    {%- endfor %}
    {%- if not ns.exclude -%}          
        {%- for schema_exclusion in schema_exclusions %} 
            {%- if schema_exclusion in schema %}
                {{ log("Match with schema exclusion list: " ~ schema ~ " excluding... " ~ schema_exclusion, info=True) }}
                {%- set ns.exclude = true %}
                {%- break %}
            {%- endif %}
         {%- endfor %}
    {%- endif %}
    {%- if not ns.exclude -%}
      {%- for role in roles %}
      GRANT ALL ON SCHEMA {{ fq_schema }} TO ROLE {{ role }};
      GRANT ALL ON ALL TABLES IN SCHEMA {{ fq_schema }} TO ROLE {{ role }};
      GRANT ALL ON ALL VIEWS IN SCHEMA {{ fq_schema }} TO ROLE {{ role }};
      {%- endfor %}
      {{ log("Granted Permissions on: " ~ fq_schema , info=True) }}
    {%- else%}
    {{ log("Excluded: " ~ fq_schema ~ " due to match with exclusion list ", info=True) }}
    {%- endif %}
  {% endfor %}
{%- endif -%}
{% endmacro %}
