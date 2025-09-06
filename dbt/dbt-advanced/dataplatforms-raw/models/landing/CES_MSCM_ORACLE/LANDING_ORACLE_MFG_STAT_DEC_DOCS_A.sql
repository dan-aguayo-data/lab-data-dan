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
    WHERE METADATA:"table-name"='MFG_STAT_DEC_DOCS_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:MFG_STAT_DEC_DOCS_ID,'')::bigint as MFG_STAT_DEC_DOCS_ID,
    nullif(N.DATA:MFG_STATUTORY_DECLARATION_ID,'')::bigint as MFG_STATUTORY_DECLARATION_ID,
    N.DATA:DOCUMENT_NAME::string as DOCUMENT_NAME,
    N.DATA:DOCUMENT_URI::string as DOCUMENT_URI,
    nullif(N.DATA:DOCUMENT_CREATED_BY,'')::string as DOCUMENT_CREATED_BY,
    nullif(N.DATA:DOCUMENT_CREATED_ON,'')::TIMESTAMP_NTZ as DOCUMENT_CREATED_ON,
    nullif(N.DATA:DOCUMENT_STATUS,'')::string as DOCUMENT_STATUS,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:DOCUMENT_TYPE,'')::string as DOCUMENT_TYPE,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N