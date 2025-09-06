{%- set trimmed_source_rel = model.name | replace("ORACLE_","") -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'PARTICIPANT_SITE_ID',
        post_hook= "delete from {{this}}
        WHERE METADATA_OPERATION ='delete'"
    )
}}


WITH SOURCE AS (
    SELECT 
    *
    FROM
        {{ ref('LANDING_ORACLE_MDT_PARTICIPANT_SITES') }}
        
), SOURCE_QUALIFY AS (

    SELECT
        s.*
    FROM
        source s
    WHERE (1=1)    
    {% if is_incremental() %}
        AND NVL(METADATA_TIMESTAMP, current_date) >= (SELECT dateadd(hour, {{ var('inc_offset') }}, max(METADATA_TIMESTAMP)) FROM {{ this }} )
    {% endif %}
    QUALIFY row_number() OVER (PARTITION BY s.PARTICIPANT_SITE_ID ORDER BY s.METADATA_TIMESTAMP DESC) = 1

)
 select * from SOURCE_QUALIFY
 WHERE (1=1) 
 {% if target.name.upper() == "PROD" %} 
    AND NOT (upper(LAST_MODIFIED_BY) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))
    AND NOT  upper(SITE_NAME) LIKE '%PVT%'
 {% endif %}