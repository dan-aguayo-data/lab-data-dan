{%- set trimmed_source_rel = model.name | replace("ORACLE_","") -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'CONTACT_ID',
        post_hook= "delete from {{this}}
        WHERE METADATA_OPERATION ='delete'"
    )
}}


WITH SOURCE AS (
    SELECT 
    *
    FROM
        {{ ref('LANDING_ORACLE_MDT_CONTACTS') }}
), SOURCE_QUALIFY AS (
SELECT
    s.*
FROM
    source s
WHERE (1=1)    
{% if is_incremental() %}
    AND NVL(METADATA_TIMESTAMP, current_date) >= (SELECT dateadd(hour, {{ var('inc_offset') }}, max(METADATA_TIMESTAMP)) FROM {{ this }} )
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.CONTACT_ID ORDER BY s.METADATA_TIMESTAMP DESC) = 1

)
SELECT * FROM SOURCE_QUALIFY 
{% if target.name.upper() == "PROD" %} 
  WHERE 1=1  AND NOT (upper(email) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))
{% endif %}