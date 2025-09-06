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
    WHERE METADATA:"table-name"='FMT_PEOPLE' AND DATA is not null
)

SELECT
    N.DATA:PERSON_ID::bigint as PERSON_ID,
    N.DATA:ORGANISATION_ID::bigint as ORGANISATION_ID,
    N.DATA:FIRST_NAME::string as FIRST_NAME,
    N.DATA:LAST_NAME::string as LAST_NAME,
    N.DATA:EMAIL::string as EMAIL,
    N.DATA:LOGIN::string as LOGIN,
    nullif(N.DATA:MOBILE_NUMBER,'')::string as MOBILE_NUMBER,
    N.DATA:ROLE::string as ROLE,
    nullif(N.DATA:PERSON_STATUS_ID,'')::bigint as PERSON_STATUS_ID,
    N.DATA:START_DATE_ACTIVE::DATE as START_DATE_ACTIVE,
    nullif(N.DATA:END_DATE_ACTIVE,'')::DATE as END_DATE_ACTIVE,
    nullif(N.DATA:DEFAULT_LOCATION_ID,'')::bigint as DEFAULT_LOCATION_ID,
    nullif(N.DATA:SESSION_TOKEN,'')::bigint as SESSION_TOKEN,
    nullif(N.DATA:TOKEN_EXPIRY,'')::DATE as TOKEN_EXPIRY,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:TERMS_COND_DATE,'')::DATE as TERMS_COND_DATE,
    nullif(N.DATA:CONTACT_TYPE,'')::string as CONTACT_TYPE,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N