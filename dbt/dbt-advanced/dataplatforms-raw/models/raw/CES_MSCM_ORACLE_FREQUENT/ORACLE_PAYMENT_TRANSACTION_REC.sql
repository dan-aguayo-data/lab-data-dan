{%- set trimmed_source_rel = model.name | replace("ORACLE_","") -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        post_hook= "delete from {{this}}
        WHERE METADATA_OPERATION ='delete'"
    )
}}


WITH SOURCE AS (
    SELECT 
    *
    FROM
        {{ ref('LANDING_ORACLE_PAYMENT_TRANSACTION_REC') }}
), SOURCE_QUALIFY AS (
SELECT
    s.*
FROM
    source s
WHERE (1=1)    
{% if is_incremental() %}
    AND NVL(METADATA_TIMESTAMP, current_date) >= (SELECT dateadd(hour, {{ var('inc_offset') }}, max(METADATA_TIMESTAMP)) FROM {{ this }} )
{% endif %}

QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.METADATA_TIMESTAMP DESC) = 1
) 

SELECT * FROM SOURCE_QUALIFY 
{% if target.name.upper() == "PROD" %} 
   WHERE 1=1 AND NOT (upper(LAST_MODIFIED_BY) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))

    and
    SCHEME_PARTICIPANT_ID not in (

    SELECT SITE_NUMBER FROM 
    (select PARTICIPANT_SITE_ID, SITE_NUMBER, SITE_NAME, last_modified_by 
     from {{ ref('LANDING_ORACLE_MDT_PARTICIPANT_SITES') }}
     QUALIFY row_number() OVER (PARTITION BY PARTICIPANT_SITE_ID ORDER BY METADATA_TIMESTAMP DESC) = 1)
    WHERE 
    UPPER(SITE_NAME) LIKE ANY ('PVT %', 'TEST %', '% PVT', '% TEST', '% PVT %', '% TEST %', 'PVT-%', 'TEST-%', '%-PVT', '%-TEST', '%-PVT-%', '%-TEST-%')
    OR
    upper(last_modified_by) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM')
  
    )

{% endif %}