{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PAYMENTSTEPDOWNEVENT_S" if is_incremental() else "PAYMENTSTEPDOWNEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'PAY_REF_NUMBER',
        enabled = run_flag_uat()
    )
}}


WITH source AS (
    SELECT
        *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}
), JSON_FLATTEN AS (
    SELECT
        s.RECORD_CONTENT:id::string AS KAFKA_ID,
        s.RECORD_CONTENT:datetime::timestamp_ntz AS KAFKA_DATETIME,
        s.RECORD_CONTENT:data:amount::float AS AMOUNT,
        s.RECORD_CONTENT:data:batchId::string AS BATCH_ID,
        s.RECORD_CONTENT:data:currency::string AS CURRENCY,
        s.RECORD_CONTENT:data:multiSchemeId::string AS MULTI_SCHEME_ID,
        s.RECORD_CONTENT:data:name::string AS NAME,
        s.RECORD_CONTENT:data:payRefNumber::string AS PAY_REF_NUMBER,
        s.RECORD_CONTENT:data:rowNumber::number AS ROW_NUMBER,
        s.RECORD_CONTENT:modifiedBy::string AS MODIFIED_BY,
        s.RECORD_CONTENT:source::string AS SOURCE,
        CASE WHEN s.RECORD_CONTENT:subject::string LIKE 'DERP%' THEN  
          SPLIT_PART(s.RECORD_CONTENT:subject::string, '_', 1) || '_' ||
          SUBSTR(s.RECORD_CONTENT:subject::string, 6, 4) ||  
          SUBSTR(s.RECORD_CONTENT:subject::string, 11, 2) || 
          SUBSTR(s.RECORD_CONTENT:subject::string, 14, 2) || 
          '_' ||
          SUBSTR(s.RECORD_CONTENT:subject::string, 16) 
          ELSE s.RECORD_CONTENT:subject::string END AS SUBJECT,
        s.RECORD_CONTENT:type::string AS TYPE
    FROM
        source AS s
)
SELECT *
FROM JSON_FLATTEN
WHERE NOT SUBJECT LIKE ANY ('VIC_DERP%','TAS_DERP%')  -- Lynda from engineering is advising to ignore these naming patterns
AND MULTI_SCHEME_ID <> ''  --bad data picked up with VIC tests , record with bad data: 61eaf45e-aba5-47a1-b59b-2aaf4eed4bae

QUALIFY row_number() OVER (PARTITION BY PAY_REF_NUMBER ORDER BY KAFKA_DATETIME DESC) = 1
