{{'{%- set trimmed_source_rel = model.name | replace("ORACLE_","") -%}'}}

{{ '{{' }}
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge'{% if INCREMENTAL_KEY_MERGE %},
        unique_key = {% if TABLE_NAME.endswith('_A')%}'AUDIT_ID'{% else %}{{ "'" + PRIMARY_KEYS[0]+ "'" if LEN(PRIMARY_KEYS) == 1 else '[' + "'" + "','".join(PRIMARY_KEYS) + "'" + ']' }}{% endif %}{% endif %},
        post_hook= "delete from {{ '{{' }}this{{ '}}' }}
        WHERE METADATA_OPERATION IN ('delete')
        {{'{%'}} if is_incremental() {{'%}'}}
        AND NVL(METADATA_TIMESTAMP, current_date) >= (SELECT dateadd(hour, {{ '{{' }} var('inc_offset') {{ '}}' }}, max(METADATA_TIMESTAMP)) FROM {{ '{{' }}this{{ '}}' }})
        {{'{%'}} endif {{'%}'}}"


    )
{{ '}}' }}


WITH SOURCE AS (
    SELECT 
    {% if TABLE_NAME.endswith('_A') and INCREMENTAL_KEY_MERGE -%}
    {{ PRIMARY_KEYS[0] if LEN(PRIMARY_KEYS) == 1 else "||'-'||".join(PRIMARY_KEYS)}}||'-'||TO_CHAR(AUDIT_DATE)||'-'||AUDIT_TYPE||'-'||AUDIT_USER as AUDIT_ID,
    {% endif -%}
    *
    FROM
        {{ '{{' }} ref('LANDING_ORACLE_{{TABLE_NAME}}') }}
)
SELECT
    s.*
FROM
    source s
WHERE (1=1)    
{{ '{% if is_incremental() %}' }}
    AND NVL(METADATA_TIMESTAMP, current_date) >= (SELECT dateadd(hour, {{ '{{' }} var('inc_offset') {{ '}}' }}, max(METADATA_TIMESTAMP)) FROM {{ '{{' }} this {{ '}}' }} )
{{ '{% endif %}' }}
{{ '{% if target.name.upper() == "PROD" %}' }} 
    AND NOT (upper(LAST_MODIFIED_BY) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))
{{ '{% endif %}' }}
{% if INCREMENTAL_KEY_MERGE %}QUALIFY row_number() OVER (PARTITION BY {% if TABLE_NAME.endswith('_A')%}s.AUDIT_ID{% else %}{{ "s." + PRIMARY_KEYS[0] if LEN(PRIMARY_KEYS) == 1 else "s." + ", s.".join(PRIMARY_KEYS) }}{% endif %} ORDER BY s.METADATA_TIMESTAMP DESC) = 1{% endif %}