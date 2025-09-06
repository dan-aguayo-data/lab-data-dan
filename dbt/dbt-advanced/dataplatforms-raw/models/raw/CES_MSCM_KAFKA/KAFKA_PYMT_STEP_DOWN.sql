{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}
{%- set src_tbl = "PAYMENTSTEPDOWNEVENT_S" if is_incremental() else "PAYMENTSTEPDOWNEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'PAY_REF_NUMBER',
        enabled = run_flag_prod()
    )
}}


WITH source AS (
    SELECT
        *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }}
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
        CASE WHEN s.RECORD_CONTENT:subject::string LIKE 'DERP%' THEN   --DERP files for VIC have a different date formatting that is accounted for in this logic, date is used downstream
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
        QUALIFY row_number() OVER (PARTITION BY PAY_REF_NUMBER ORDER BY KAFKA_DATETIME DESC) = 1
)
SELECT *
FROM JSON_FLATTEN
WHERE (1=1) 
AND NOT (upper(NVL(MODIFIED_BY,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))
AND NOT SUBJECT LIKE ANY ('VIC_DERP%','TAS_DERP%')  -- Lynda from engineering is advising to ignore 