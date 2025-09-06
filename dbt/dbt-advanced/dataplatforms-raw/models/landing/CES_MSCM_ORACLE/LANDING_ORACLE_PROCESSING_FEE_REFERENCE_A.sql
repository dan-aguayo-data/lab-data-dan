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
    WHERE METADATA:"table-name"='PROCESSING_FEE_REFERENCE_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:SCHEME_ID,'')::string as SCHEME_ID,
    nullif(N.DATA:SCHEME_PARTICIPANT_ID,'')::string as SCHEME_PARTICIPANT_ID,
    nullif(N.DATA:MATERIAL_TYPE_ID,'')::string as MATERIAL_TYPE_ID,
    nullif(N.DATA:AMOUNT,'')::float as AMOUNT,
    nullif(N.DATA:EFFECTIVE_FROM,'')::TIMESTAMP_NTZ as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::TIMESTAMP_NTZ as EFFECTIVE_TO,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_PARTICIPANT_SITE_ID,'')::bigint as MSC_PARTICIPANT_SITE_ID,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N