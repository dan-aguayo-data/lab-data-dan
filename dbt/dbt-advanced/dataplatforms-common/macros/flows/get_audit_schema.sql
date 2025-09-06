{% macro get_audit_schema() %}
{#
    The "logging" dbt package module has a macro called "get_audit_schema".
    This will overide it, ensuring that the base "DBT_AUDIT_LOG" table ends up 
        in the same schema as the logging module's STG_* views 
    The name is special, don't change it.
#}
    {% set audit_schema = resolve_schema_name("META", var('branch')) %}

    {{ return(audit_schema) }}

{% endmacro %}
