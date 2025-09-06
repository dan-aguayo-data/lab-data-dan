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
    WHERE METADATA:"table-name"='MDT_PARTICIPANTS' AND DATA is not null
)

SELECT
    N.DATA:PARTICIPANT_ID::bigint as PARTICIPANT_ID,
    N.DATA:PARTICIPANT_NUMBER::bigint as PARTICIPANT_NUMBER,
    N.DATA:PARTICIPANT_GROUP_ID::bigint as PARTICIPANT_GROUP_ID,
    nullif(N.DATA:CONSUMER_NUMBER,'')::string as CONSUMER_NUMBER,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    N.DATA:PARTICIPANT_NAME::string as PARTICIPANT_NAME,
    nullif(N.DATA:ALTERNATE_NAME,'')::string as ALTERNATE_NAME,
    nullif(N.DATA:LEGAL_NAME,'')::string as LEGAL_NAME,
    nullif(N.DATA:TAX_REG_COUNTRY_ID,'')::bigint as TAX_REG_COUNTRY_ID,
    nullif(N.DATA:TAX_REGISTRATION_NUMBER,'')::string as TAX_REGISTRATION_NUMBER,
    nullif(N.DATA:COMPANY_NUMBER_TYPE_ID,'')::bigint as COMPANY_NUMBER_TYPE_ID,
    nullif(N.DATA:COMPANY_NUMBER,'')::string as COMPANY_NUMBER,
    nullif(N.DATA:ERP_BUSINESS_RELATIONSHIP,'')::string as ERP_BUSINESS_RELATIONSHIP,
    nullif(N.DATA:AP_TAX_CLASS,'')::string as AP_TAX_CLASS,
    nullif(N.DATA:AR_TAX_CLASS,'')::string as AR_TAX_CLASS,
    N.DATA:GST_REGISTERED::bigint as GST_REGISTERED,
    N.DATA:GST_CONCESSION::bigint as GST_CONCESSION,
    nullif(N.DATA:TAX_ORGANIZATION_TYPE,'')::string as TAX_ORGANIZATION_TYPE,
    nullif(N.DATA:ERP_REGISTRY_ID,'')::bigint as ERP_REGISTRY_ID,
    nullif(N.DATA:ERP_SUPPLIER_TYPE,'')::string as ERP_SUPPLIER_TYPE,
    nullif(N.DATA:ESTABLISHED_DATE,'')::DATE as ESTABLISHED_DATE,
    nullif(N.DATA:INACTIVE_DATE,'')::DATE as INACTIVE_DATE,
    nullif(N.DATA:GENDER,'')::string as GENDER,
    nullif(N.DATA:AGE_BRACKET_ID,'')::bigint as AGE_BRACKET_ID,
    N.DATA:AGE_CONFIRMATION::bigint as AGE_CONFIRMATION,
    nullif(N.DATA:REG_ADDR_CONTACT_COUNTRY_CODE,'')::string as REG_ADDR_CONTACT_COUNTRY_CODE,
    nullif(N.DATA:REG_ADDR_CONTACT_AREA_CODE,'')::string as REG_ADDR_CONTACT_AREA_CODE,
    nullif(N.DATA:REG_ADDR_CONTACT_PHONE_NUMBER,'')::string as REG_ADDR_CONTACT_PHONE_NUMBER,
    nullif(N.DATA:REG_ADDR_CONTACT_PHONE_EXT,'')::string as REG_ADDR_CONTACT_PHONE_EXT,
    nullif(N.DATA:REG_ADDR_CONTACT_EMAIL,'')::string as REG_ADDR_CONTACT_EMAIL,
    nullif(N.DATA:REG_ADDR_ADDRESS_LINE_1,'')::string as REG_ADDR_ADDRESS_LINE_1,
    nullif(N.DATA:REG_ADDR_ADDRESS_LINE_2,'')::string as REG_ADDR_ADDRESS_LINE_2,
    nullif(N.DATA:REG_ADDR_CITY_SUBURB,'')::string as REG_ADDR_CITY_SUBURB,
    nullif(N.DATA:REG_ADDR_STATE,'')::string as REG_ADDR_STATE,
    nullif(N.DATA:REG_ADDR_POST_CODE,'')::string as REG_ADDR_POST_CODE,
    nullif(N.DATA:REG_ADDR_COUNTRY_ID,'')::bigint as REG_ADDR_COUNTRY_ID,
    nullif(N.DATA:WEB_SITE_URL,'')::string as WEB_SITE_URL,
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