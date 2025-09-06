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
    WHERE METADATA:"table-name"='MDT_SCHEME_CONTRACT_ORGS' AND DATA is not null
)

SELECT
    N.DATA:CONTRACT_ORGANIZATION_ID::bigint as CONTRACT_ORGANIZATION_ID,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    N.DATA:PARTICIPANT_ID::bigint as PARTICIPANT_ID,
    N.DATA:CONTRACT_ORGANIZATION_NUMBER::string as CONTRACT_ORGANIZATION_NUMBER,
    nullif(N.DATA:CRM_CONTRACT_ORG_ID,'')::bigint as CRM_CONTRACT_ORG_ID,
    nullif(N.DATA:CONTRACT_TYPE,'')::string as CONTRACT_TYPE,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:ESTABLISHED_DATE,'')::DATE as ESTABLISHED_DATE,
    nullif(N.DATA:INACTIVE_DATE,'')::DATE as INACTIVE_DATE,
    nullif(N.DATA:CURRENT_CONTRACT_EXPIRY_DATE,'')::DATE as CURRENT_CONTRACT_EXPIRY_DATE,
    nullif(N.DATA:CURRENT_CONTRACT_TERM,'')::bigint as CURRENT_CONTRACT_TERM,
    nullif(N.DATA:CONTRACT_MANAGER,'')::string as CONTRACT_MANAGER,
    nullif(N.DATA:ATTRIBUTE_CATEGORY,'')::string as ATTRIBUTE_CATEGORY,
    nullif(N.DATA:ATTRIBUTE1,'')::string as ATTRIBUTE1,
    nullif(N.DATA:ATTRIBUTE2,'')::string as ATTRIBUTE2,
    nullif(N.DATA:ATTRIBUTE3,'')::string as ATTRIBUTE3,
    nullif(N.DATA:ATTRIBUTE4,'')::string as ATTRIBUTE4,
    nullif(N.DATA:ATTRIBUTE5,'')::string as ATTRIBUTE5,
    nullif(N.DATA:ATTRIBUTE6,'')::string as ATTRIBUTE6,
    nullif(N.DATA:ATTRIBUTE7,'')::string as ATTRIBUTE7,
    nullif(N.DATA:ATTRIBUTE8,'')::string as ATTRIBUTE8,
    nullif(N.DATA:ATTRIBUTE9,'')::string as ATTRIBUTE9,
    nullif(N.DATA:ATTRIBUTE10,'')::string as ATTRIBUTE10,
    nullif(N.DATA:ATTRIBUTE11,'')::string as ATTRIBUTE11,
    nullif(N.DATA:ATTRIBUTE12,'')::string as ATTRIBUTE12,
    nullif(N.DATA:ATTRIBUTE13,'')::string as ATTRIBUTE13,
    nullif(N.DATA:ATTRIBUTE14,'')::string as ATTRIBUTE14,
    nullif(N.DATA:ATTRIBUTE15,'')::string as ATTRIBUTE15,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N