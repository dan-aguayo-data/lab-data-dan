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
    WHERE METADATA:"table-name"='MRF_VOLUME_HDR' AND DATA is not null
)

SELECT
    N.DATA:MRF_VOLUME_HDR_ID::string as MRF_VOLUME_HDR_ID,
    N.DATA:MRF_ID::string as MRF_ID,
    N.DATA:MSC_PARTICIPANT_SITE_ID::bigint as MSC_PARTICIPANT_SITE_ID,
    N.DATA:TRANSACTION_ID::string as TRANSACTION_ID,
    N.DATA:STATUS::string as STATUS,
    N.DATA:SUBMITTED_BY::string as SUBMITTED_BY,
    N.DATA:SUBMITTED_ON::TIMESTAMP_NTZ as SUBMITTED_ON,
    N.DATA:TRANSACTED_BY::string as TRANSACTED_BY,
    N.DATA:TRANSACTED_ON::TIMESTAMP_NTZ as TRANSACTED_ON,
    N.DATA:ENTRY_TYPE::string as ENTRY_TYPE,
    N.DATA:PERIOD::string as PERIOD,
    N.DATA:PERIOD_TYPE::string as PERIOD_TYPE,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    N.DATA:VENDOR_ID::string as VENDOR_ID,
    N.DATA:TOTAL_UNITS::float as TOTAL_UNITS,
    nullif(N.DATA:TOTAL_KILOS,'')::float as TOTAL_KILOS,
    nullif(N.DATA:ATTRIBUTE1,'')::string as ATTRIBUTE1,
    nullif(N.DATA:ATTRIBUTE2,'')::string as ATTRIBUTE2,
    nullif(N.DATA:ATTRIBUTE3,'')::string as ATTRIBUTE3,
    nullif(N.DATA:ATTRIBUTE4,'')::string as ATTRIBUTE4,
    nullif(N.DATA:ATTRIBUTE5,'')::string as ATTRIBUTE5,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N