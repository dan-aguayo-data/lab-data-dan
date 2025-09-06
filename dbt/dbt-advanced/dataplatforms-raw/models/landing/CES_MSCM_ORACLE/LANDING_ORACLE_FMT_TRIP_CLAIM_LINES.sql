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
    WHERE METADATA:"table-name"='FMT_TRIP_CLAIM_LINES' AND DATA is not null
)

SELECT
    N.DATA:TRIP_CLAIM_LINE_ID::bigint as TRIP_CLAIM_LINE_ID,
    N.DATA:TRIP_CLAIM_ID::bigint as TRIP_CLAIM_ID,
    nullif(N.DATA:TRIP_LEG_ID,'')::bigint as TRIP_LEG_ID,
    N.DATA:LINE_NUM::bigint as LINE_NUM,
    nullif(N.DATA:VEHICLE_RATE_ID,'')::bigint as VEHICLE_RATE_ID,
    N.DATA:CHARGE_TYPE_ID::bigint as CHARGE_TYPE_ID,
    N.DATA:CHARGE_QTY::bigint as CHARGE_QTY,
    N.DATA:CHARGE_UOM_ID::bigint as CHARGE_UOM_ID,
    N.DATA:CHARGE_STATUS_ID::bigint as CHARGE_STATUS_ID,
    N.DATA:CHARGE_AMOUNT::float as CHARGE_AMOUNT,
    nullif(N.DATA:CHARGE_REASON_ID,'')::bigint as CHARGE_REASON_ID,
    nullif(N.DATA:NOTES,'')::string as NOTES,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:CHARGE_RATE,'')::float as CHARGE_RATE,
    nullif(N.DATA:ERP_RECEIPT_LINE_ID,'')::bigint as ERP_RECEIPT_LINE_ID,
    nullif(N.DATA:ERP_RECEIPT_LINE_NUMBER,'')::bigint as ERP_RECEIPT_LINE_NUMBER,
    nullif(N.DATA:ERP_RECEIPT_NUMBER,'')::bigint as ERP_RECEIPT_NUMBER,
    nullif(N.DATA:ERP_INVOICE_LINE_NUMBER,'')::bigint as ERP_INVOICE_LINE_NUMBER,
    nullif(N.DATA:ADJUSTMENT_INVOICE_NUMBER,'')::bigint as ADJUSTMENT_INVOICE_NUMBER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N