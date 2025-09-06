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
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_COEX') }}
    WHERE METADATA:"table-name"='FMT_TRIP_CLAIM_LINE_ADJUSTMENTS' AND DATA is not null
)

SELECT
    N.DATA:LINE_ADJUSTMENT_ID::bigint as LINE_ADJUSTMENT_ID,
    N.DATA:CLAIM_LINE_ID::bigint as CLAIM_LINE_ID,
    N.DATA:ADJUSTMENT_SEQ::bigint as ADJUSTMENT_SEQ,
    N.DATA:PRIOR_QTY::bigint as PRIOR_QTY,
    N.DATA:NEW_QTY::bigint as NEW_QTY,
    nullif(N.DATA:PRIOR_VEHICLE_RATE_ID,'')::bigint as PRIOR_VEHICLE_RATE_ID,
    nullif(N.DATA:NEW_VEHICLE_RATE_ID,'')::bigint as NEW_VEHICLE_RATE_ID,
    N.DATA:ADJUSTMENT_AMOUNT::float as ADJUSTMENT_AMOUNT,
    nullif(N.DATA:ERP_RCV_TXN_ID,'')::bigint as ERP_RCV_TXN_ID,
    N.DATA:ADJUST_REASON_ID::bigint as ADJUST_REASON_ID,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:ERP_RECEIPT_NUMBER,'')::bigint as ERP_RECEIPT_NUMBER,
    nullif(N.DATA:ERP_RECEIPT_LINE,'')::bigint as ERP_RECEIPT_LINE,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N