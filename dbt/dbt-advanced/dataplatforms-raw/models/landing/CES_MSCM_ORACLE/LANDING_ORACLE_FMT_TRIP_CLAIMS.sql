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
    WHERE METADATA:"table-name"='FMT_TRIP_CLAIMS' AND DATA is not null
)

SELECT
    N.DATA:TRIP_CLAIM_ID::bigint as TRIP_CLAIM_ID,
    nullif(N.DATA:ORGANISATION_ID,'')::bigint as ORGANISATION_ID,
    N.DATA:CLAIM_TYPE_ID::bigint as CLAIM_TYPE_ID,
    N.DATA:CLAIM_STATUS_ID::bigint as CLAIM_STATUS_ID,
    N.DATA:CLAIM_DATE::DATE as CLAIM_DATE,
    nullif(N.DATA:RECEIPT_ID,'')::bigint as RECEIPT_ID,
    N.DATA:PO_NUMBER::string as PO_NUMBER,
    nullif(N.DATA:SUBMITTED_BY,'')::string as SUBMITTED_BY,
    nullif(N.DATA:INVOICE_NUMBER,'')::string as INVOICE_NUMBER,
    nullif(N.DATA:SUPPLIER_INVOICE_TOTAL,'')::float as SUPPLIER_INVOICE_TOTAL,
    nullif(N.DATA:ERP_INVOICE_ID,'')::bigint as ERP_INVOICE_ID,
    nullif(N.DATA:LAST_PAYMENT_DATE,'')::DATE as LAST_PAYMENT_DATE,
    nullif(N.DATA:ERP_PAYMENT_NO,'')::string as ERP_PAYMENT_NO,
    nullif(N.DATA:ERP_RECEIPT_NO,'')::bigint as ERP_RECEIPT_NO,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N