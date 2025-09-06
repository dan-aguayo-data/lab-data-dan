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
    WHERE METADATA:"table-name"='MDT_CONTACTS_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:CONTACT_ID,'')::bigint as CONTACT_ID,
    nullif(N.DATA:SALUTATION,'')::string as SALUTATION,
    nullif(N.DATA:FIRST_NAME,'')::string as FIRST_NAME,
    nullif(N.DATA:LAST_NAME,'')::string as LAST_NAME,
    nullif(N.DATA:JOB_TITLE,'')::string as JOB_TITLE,
    nullif(N.DATA:PRIMARY,'')::bigint as PRIMARY,
    nullif(N.DATA:COUNTRY_CODE,'')::string as COUNTRY_CODE,
    nullif(N.DATA:AREA_CODE,'')::string as AREA_CODE,
    nullif(N.DATA:PHONE_NUMBER,'')::string as PHONE_NUMBER,
    nullif(N.DATA:PHONE_EXT,'')::string as PHONE_EXT,
    nullif(N.DATA:MOBILE_PHONE_COUNTRY_CODE,'')::string as MOBILE_PHONE_COUNTRY_CODE,
    nullif(N.DATA:MOBILE_PHONE_AREA_CODE,'')::string as MOBILE_PHONE_AREA_CODE,
    nullif(N.DATA:MOBILE_PHONE_NUMBER,'')::string as MOBILE_PHONE_NUMBER,
    nullif(N.DATA:EMAIL,'')::string as EMAIL,
    nullif(N.DATA:ACTIVE,'')::bigint as ACTIVE,
    nullif(N.DATA:EFFECTIVE_START_DATE,'')::DATE as EFFECTIVE_START_DATE,
    nullif(N.DATA:EFFECTIVE_END_DATE,'')::DATE as EFFECTIVE_END_DATE,
    nullif(N.DATA:CRM_LOGIN_ID,'')::string as CRM_LOGIN_ID,
    nullif(N.DATA:CRM_CONTACT_ID,'')::bigint as CRM_CONTACT_ID,
    nullif(N.DATA:ERP_PERSON_PROFILE_ID,'')::bigint as ERP_PERSON_PROFILE_ID,
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
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    nullif(N.DATA:SUPPLIED_CONSUMER_EMAIL,'')::string as SUPPLIED_CONSUMER_EMAIL,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N