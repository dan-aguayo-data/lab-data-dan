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
    WHERE METADATA:"table-name"='MFG_SALES_VOLUME_HDR_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:MANUFACTURER_ID,'')::string as MANUFACTURER_ID,
    nullif(N.DATA:PERIOD,'')::string as PERIOD,
    nullif(N.DATA:PERIOD_TYPE,'')::string as PERIOD_TYPE,
    nullif(N.DATA:ENTRY_TYPE,'')::string as ENTRY_TYPE,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:SUBMITTED_BY,'')::string as SUBMITTED_BY,
    nullif(N.DATA:SUBMITTED_DATE,'')::TIMESTAMP_NTZ as SUBMITTED_DATE,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_MANUFACTURER_SITE_ID,'')::bigint as MSC_MANUFACTURER_SITE_ID,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    nullif(N.DATA:ADJUSTMENT_REASON,'')::string as ADJUSTMENT_REASON,
    nullif(N.DATA:SS_AUDIT_ADJUSTMENT_ID,'')::bigint as SS_AUDIT_ADJUSTMENT_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N