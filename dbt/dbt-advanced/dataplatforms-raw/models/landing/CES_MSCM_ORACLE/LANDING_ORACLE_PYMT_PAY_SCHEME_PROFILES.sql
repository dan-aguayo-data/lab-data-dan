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
    WHERE METADATA:"table-name"='PYMT_PAY_SCHEME_PROFILES' AND DATA is not null
)

SELECT
    N.DATA:PAY_SCHEME_PROFILE_ID::bigint as PAY_SCHEME_PROFILE_ID,
    nullif(N.DATA:PAYMENT_METHOD,'')::string as PAYMENT_METHOD,
    nullif(N.DATA:PAYMENT_LEGAL_ENTITY,'')::string as PAYMENT_LEGAL_ENTITY,
    nullif(N.DATA:BANK_ACCOUNT_ID,'')::bigint as BANK_ACCOUNT_ID,
    nullif(N.DATA:DEFAULT_FLAG,'')::string as DEFAULT_FLAG,
    nullif(N.DATA:START_DATE_ACTIVE,'')::DATE as START_DATE_ACTIVE,
    nullif(N.DATA:END_DATE_ACTIVE,'')::DATE as END_DATE_ACTIVE,
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
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:LAST_UPDATE_LOGIN,'')::string as LAST_UPDATE_LOGIN,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:SCHEME_ID,'')::string as SCHEME_ID,
    nullif(N.DATA:ACTIVE_FLAG,'')::string as ACTIVE_FLAG,
    nullif(N.DATA:ERP_PAY_GROUP,'')::string as ERP_PAY_GROUP,
    nullif(N.DATA:ERP_PAYMENT_METHOD,'')::string as ERP_PAYMENT_METHOD,
    nullif(N.DATA:ERP_PAYMENT_METHOD_CDE,'')::string as ERP_PAYMENT_METHOD_CDE,
    nullif(N.DATA:PAYMENT_DOCUMENT,'')::string as PAYMENT_DOCUMENT,
    nullif(N.DATA:PAYMENT_PROCESS_PROFILE,'')::string as PAYMENT_PROCESS_PROFILE,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N