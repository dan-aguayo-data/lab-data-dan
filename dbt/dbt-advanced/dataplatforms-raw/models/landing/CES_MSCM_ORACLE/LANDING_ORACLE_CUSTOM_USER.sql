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
    WHERE METADATA:"table-name"='CUSTOM_USER' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:LOGIN_ID::string as LOGIN_ID,
    nullif(N.DATA:TYPE,'')::string as TYPE,
    nullif(N.DATA:FIRST_NAME,'')::string as FIRST_NAME,
    nullif(N.DATA:LAST_NAME,'')::string as LAST_NAME,
    nullif(N.DATA:MOBILE,'')::string as MOBILE,
    nullif(N.DATA:IDCS_SYNCED,'')::bigint as IDCS_SYNCED,
    nullif(N.DATA:SAAS_SYNCED,'')::bigint as SAAS_SYNCED,
    nullif(N.DATA:IDCS_USER_ID,'')::string as IDCS_USER_ID,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:DEFAULT_SCHEME_ID,'')::string as DEFAULT_SCHEME_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MFA_FAIL_COUNT,'')::bigint as MFA_FAIL_COUNT,
    nullif(N.DATA:LAST_PWD_CHANGE_ATTEMPT,'')::DATE as LAST_PWD_CHANGE_ATTEMPT,
    nullif(N.DATA:PWD_CHANGE_ATTEMPTS,'')::bigint as PWD_CHANGE_ATTEMPTS,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N