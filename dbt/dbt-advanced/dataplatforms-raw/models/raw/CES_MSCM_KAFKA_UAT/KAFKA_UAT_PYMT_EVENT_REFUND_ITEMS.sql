{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PAYMENT_REFUND_ITEMS_UAT_S" if is_incremental() else "PAYMENTEVENT" -%}

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
    LATERAL FLATTEN (input => parse_json(RECORD_CONTENT), path => 'data.refundEvent.refundItems') f

), PYMT_FLATTEN AS (

SELECT
     concat(s.RECORD_CONTENT:data:refundEvent:refundTransactionId::string, '-', s.value:materialTypeId::string) as ID
    ,s.RECORD_CONTENT:data:refundEvent:multiSchemeId::number as MULTI_SCHEME_ID
    ,s.RECORD_CONTENT:data:refundEvent:refundTransactionId::string as TRANSACTION_ID
    ,s.value:materialTypeId::string as MATERIAL_TYPE_ID
    ,s.value:materialTypeName::string as MATERIAL_TYPE_NAME
    ,s.value:containerCount::string as CONTAINER_COUNT
    ,s.value:unitPrice::float as UNIT_PRICE
    ,s.value:totalAmount::float as TOTAL_AMOUNT
    ,s.value:taxableAmount::float as TAXABLE_AMOUNT
    ,s.RECORD_CONTENT:datetime::TIMESTAMP_NTZ as KAFKA_DATETIME
FROM
source as s
)
SELECT * FROM PYMT_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1