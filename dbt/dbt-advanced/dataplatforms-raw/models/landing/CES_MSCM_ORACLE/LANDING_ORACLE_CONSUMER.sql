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
    WHERE METADATA:"table-name"='CONSUMER' AND DATA is not null
)

SELECT
    N.DATA:SCHEME_PARTICIPANT_ID::string as SCHEME_PARTICIPANT_ID,
    nullif(N.DATA:CONTACT_FIRST_NAME,'')::string as CONTACT_FIRST_NAME,
    nullif(N.DATA:CONTACT_LAST_NAME,'')::string as CONTACT_LAST_NAME,
    nullif(N.DATA:CONTACT_EMAIL,'')::string as CONTACT_EMAIL,
    nullif(N.DATA:COMPANY_EMAIL,'')::string as COMPANY_EMAIL,
    nullif(N.DATA:INDIVIDUAL_CONSUMER,'')::bigint as INDIVIDUAL_CONSUMER,
    nullif(N.DATA:CHARITY_REGISTRATION_NUMBER,'')::string as CHARITY_REGISTRATION_NUMBER,
    nullif(N.DATA:GST_REGISTERED,'')::bigint as GST_REGISTERED,
    nullif(N.DATA:GST_CONCESSION,'')::bigint as GST_CONCESSION,
    nullif(N.DATA:IS_COMMUNITY_GROUP,'')::bigint as IS_COMMUNITY_GROUP,
    nullif(N.DATA:GENDER,'')::string as GENDER,
    nullif(N.DATA:AGE_BRACKET,'')::string as AGE_BRACKET,
    nullif(N.DATA:AGE_CONFIRMATION,'')::bigint as AGE_CONFIRMATION,
    nullif(N.DATA:TERMS_AND_CONDITIONS_ACCEPTED,'')::bigint as TERMS_AND_CONDITIONS_ACCEPTED,
    nullif(N.DATA:SYNCED,'')::bigint as SYNCED,
    nullif(N.DATA:CHARITY,'')::bigint as CHARITY,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:BANK_ACCOUNT_ID,'')::bigint as BANK_ACCOUNT_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N