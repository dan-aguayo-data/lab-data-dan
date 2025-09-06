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
    WHERE METADATA:"table-name"='INV_AP_INVOICE_DIST_INT' AND DATA is not null
)

SELECT
    N.DATA:AP_INVOICE_DIST_INT_ID::bigint as AP_INVOICE_DIST_INT_ID,
    nullif(N.DATA:AP_INVOICE_LINE_INT_ID,'')::bigint as AP_INVOICE_LINE_INT_ID,
    nullif(N.DATA:DIST_COMBINATION,'')::string as DIST_COMBINATION,
    nullif(N.DATA:AMOUNT,'')::float as AMOUNT,
    nullif(N.DATA:DIST_LINE_NUMBER,'')::bigint as DIST_LINE_NUMBER,
    nullif(N.DATA:DIST_LINE_TYPE,'')::string as DIST_LINE_TYPE,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N