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
    WHERE METADATA:"table-name"='MDT_SCHEME_CONTRACTS_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:CONTRACT_ID,'')::bigint as CONTRACT_ID,
    nullif(N.DATA:CONTRACT_ORGANIZATION_ID,'')::bigint as CONTRACT_ORGANIZATION_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:PARTICIPANT_ID,'')::bigint as PARTICIPANT_ID,
    nullif(N.DATA:CRM_CONTRACT_DOC_ID,'')::bigint as CRM_CONTRACT_DOC_ID,
    nullif(N.DATA:CONTRACT_NUMBER,'')::string as CONTRACT_NUMBER,
    nullif(N.DATA:DOCUMENT_TYPE,'')::string as DOCUMENT_TYPE,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:EFFECTIVE_START_DATE,'')::DATE as EFFECTIVE_START_DATE,
    nullif(N.DATA:EFFECTIVE_END_DATE,'')::DATE as EFFECTIVE_END_DATE,
    nullif(N.DATA:CMS_LAST_UPDATED,'')::DATE as CMS_LAST_UPDATED,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N