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
    WHERE METADATA:"table-name"='PROCESSOR_RECEIPT_HDR' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:PROCESSOR_ID::string as PROCESSOR_ID,
    N.DATA:CRP_SHIPPING_MANIFEST_HDR_ID::string as CRP_SHIPPING_MANIFEST_HDR_ID,
    N.DATA:RECEIPT_ID::string as RECEIPT_ID,
    N.DATA:STATUS::string as STATUS,
    N.DATA:PERIOD::string as PERIOD,
    N.DATA:PERIOD_TYPE::string as PERIOD_TYPE,
    N.DATA:SUBMITTED_BY::string as SUBMITTED_BY,
    N.DATA:SUBMITTED_ON::TIMESTAMP_NTZ as SUBMITTED_ON,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_PROCESSOR_SITE_ID,'')::bigint as MSC_PROCESSOR_SITE_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N