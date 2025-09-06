{%- set trimmed_source_rel = model.name | replace("LANDING_ORACLE_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH SOURCE AS (
    SELECT
        *
    FROM
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM') }}
    WHERE METADATA:"table-name"='CONSUMER_REFUND_TXN_DTL' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:TRANSACTION_ID::string as TRANSACTION_ID,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    N.DATA:QUANTITY::bigint as QUANTITY,
    N.DATA:REFUND_PER_UNIT::bigint as REFUND_PER_UNIT,
    nullif(N.DATA:GROSS_AMOUNT,'')::float as GROSS_AMOUNT,
    nullif(N.DATA:TAXABLE_AMOUNT,'')::float as TAXABLE_AMOUNT,
    nullif(N.DATA:GST_AMOUNT,'')::float as GST_AMOUNT,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:SHIPPER_UNIT_ID,'')::bigint as SHIPPER_UNIT_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N