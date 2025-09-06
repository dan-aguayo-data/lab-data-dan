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
    WHERE METADATA:"table-name"='MDT_CONTACT_ROLES' AND DATA is not null
)

SELECT
    N.DATA:CONTACT_ROLE_ID::bigint as CONTACT_ROLE_ID,
    N.DATA:CONTACT_ID::bigint as CONTACT_ID,
    N.DATA:PARTICIPANT_ID::bigint as PARTICIPANT_ID,
    nullif(N.DATA:ASSIGNMENT_TYPE,'')::string as ASSIGNMENT_TYPE,
    nullif(N.DATA:ROLE_TYPE_ID,'')::bigint as ROLE_TYPE_ID,
    nullif(N.DATA:PARTICIPANT_SITE_ID,'')::bigint as PARTICIPANT_SITE_ID,
    nullif(N.DATA:CONTRACT_ORG_ID,'')::bigint as CONTRACT_ORG_ID,
    nullif(N.DATA:CRM_ROLE_ID,'')::bigint as CRM_ROLE_ID,
    nullif(N.DATA:CRM_CONTACT_ID,'')::bigint as CRM_CONTACT_ID,
    N.DATA:ACTIVE::bigint as ACTIVE,
    nullif(N.DATA:EFFECTIVE_START_DATE,'')::DATE as EFFECTIVE_START_DATE,
    nullif(N.DATA:EFFECTIVE_END_DATE,'')::DATE as EFFECTIVE_END_DATE,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N