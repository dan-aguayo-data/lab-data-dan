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
    WHERE METADATA:"table-name"='MFA_REQUESTS_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:MFA_REQUEST_ID,'')::bigint as MFA_REQUEST_ID,
    nullif(N.DATA:USER_ID,'')::string as USER_ID,
    nullif(N.DATA:MFA_METHOD,'')::string as MFA_METHOD,
    nullif(N.DATA:CODE,'')::string as CODE,
    nullif(N.DATA:USED_ON,'')::TIMESTAMP_NTZ as USED_ON,
    nullif(N.DATA:EXPIRED,'')::string as EXPIRED,
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