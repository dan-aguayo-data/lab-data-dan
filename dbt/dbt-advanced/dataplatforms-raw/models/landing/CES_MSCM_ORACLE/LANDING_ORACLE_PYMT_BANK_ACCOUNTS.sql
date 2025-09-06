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
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM_SEC') }}
    WHERE METADATA:"table-name"='PYMT_BANK_ACCOUNTS' AND DATA is not null
)

SELECT
    N.DATA:BANK_ACCOUNT_ID::bigint as BANK_ACCOUNT_ID,
    N.DATA:BANK_NAME::string as BANK_NAME,
    N.DATA:BANK_CODE::string as BANK_CODE,
    N.DATA:BRANCH_CODE::string as BRANCH_CODE,
    N.DATA:BANK_ACCOUNT_NAME::string as BANK_ACCOUNT_NAME,
    N.DATA:BANK_ACCOUNT_NUM::string as BANK_ACCOUNT_NUM,
    nullif(N.DATA:BANK_ACCOUNT_TYPE,'')::string as BANK_ACCOUNT_TYPE,
    nullif(N.DATA:START_DATE,'')::DATE as START_DATE,
    nullif(N.DATA:END_DATE,'')::DATE as END_DATE,
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
    nullif(N.DATA:ERP_ACCOUNT_ID,'')::bigint as ERP_ACCOUNT_ID,
    nullif(N.DATA:PAY_PARTY_PROFILE_ID,'')::bigint as PAY_PARTY_PROFILE_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N