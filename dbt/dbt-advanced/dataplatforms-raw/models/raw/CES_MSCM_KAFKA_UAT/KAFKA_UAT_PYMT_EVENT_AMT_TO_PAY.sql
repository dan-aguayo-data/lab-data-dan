{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PAYMENT_AMT_TO_PAY_UAT_S" if is_incremental() else "PAYMENTEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_uat()
    )
}}

WITH source AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }} s,
    LATERAL FLATTEN (input => parse_json(RECORD_CONTENT), path => 'data.amountToPay.materials') as f

), PYMT_FLATTEN AS (

SELECT
     CONCAT(s.RECORD_CONTENT:data:paymentId::string, '-', s.value:materialTypeId::string) as ID
    ,s.RECORD_CONTENT:id::string as KAFKA_ID 
    ,s.RECORD_CONTENT:data:refundEvent:multiSchemeId::number as MULTI_SCHEME_ID
    ,s.RECORD_CONTENT:data:paymentId::string as PAYMENT_ID
    ,s.value:materialTypeId::string as MATERIAL_TYPE_ID 
    ,s.RECORD_CONTENT:data:amountToPay:currency::string as CURRENCY
    ,s.value:amountToPay::float as AMOUNT_TO_PAY
    ,s.RECORD_CONTENT:datetime::TIMESTAMP_NTZ as KAFKA_DATETIME

FROM
source as s
)
SELECT * FROM PYMT_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1