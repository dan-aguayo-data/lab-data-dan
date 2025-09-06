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
    WHERE METADATA:"table-name"='SCHEME_PRODUCT' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:SCHEME_ID::string as SCHEME_ID,
    N.DATA:PRODUCT_ID::string as PRODUCT_ID,
    N.DATA:MANUFACTURER_ID::string as MANUFACTURER_ID,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    nullif(N.DATA:MATERIAL_TYPE_OTHER,'')::string as MATERIAL_TYPE_OTHER,
    nullif(N.DATA:EXPIRY_DATE,'')::DATE as EXPIRY_DATE,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:SUBMITTED_BY,'')::string as SUBMITTED_BY,
    nullif(N.DATA:SUBMITTED_DATE,'')::DATE as SUBMITTED_DATE,
    nullif(N.DATA:SUBMITTED_SOURCE,'')::string as SUBMITTED_SOURCE,
    nullif(N.DATA:APPROVED_BY,'')::string as APPROVED_BY,
    nullif(N.DATA:APPROVED_DATE,'')::DATE as APPROVED_DATE,
    nullif(N.DATA:APPROVED_SOURCE,'')::string as APPROVED_SOURCE,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_MANUFACTURER_SITE_ID,'')::bigint as MSC_MANUFACTURER_SITE_ID,
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
    nullif(N.DATA:ATTRIBUTE16,'')::string as ATTRIBUTE16,
    nullif(N.DATA:ATTRIBUTE17,'')::string as ATTRIBUTE17,
    nullif(N.DATA:ATTRIBUTE18,'')::string as ATTRIBUTE18,
    nullif(N.DATA:ATTRIBUTE19,'')::string as ATTRIBUTE19,
    nullif(N.DATA:ATTRIBUTE20,'')::string as ATTRIBUTE20,
    nullif(N.DATA:STATUS_CHANGED_ON,'')::DATE as STATUS_CHANGED_ON,
    nullif(N.DATA:RECOMMENDATION_TEXT,'')::string as RECOMMENDATION_TEXT,
    nullif(N.DATA:EFFECTIVE_FROM,'')::DATE as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::DATE as EFFECTIVE_TO,
    nullif(N.DATA:SUSPENSION_END_DATE,'')::DATE as SUSPENSION_END_DATE,
    nullif(N.DATA:STATUS_CHANGE_TEXT,'')::string as STATUS_CHANGE_TEXT,
    nullif(N.DATA:SUPPORTING_DOC_SENT,'')::bigint as SUPPORTING_DOC_SENT,
    nullif(N.DATA:RECOMMENDATION,'')::string as RECOMMENDATION,
    nullif(N.DATA:MSC_RECIPIENT_SITE_ID,'')::bigint as MSC_RECIPIENT_SITE_ID,
    nullif(N.DATA:GO_LIVE,'')::DATE as GO_LIVE,
    nullif(N.DATA:MATERIAL_TYPE_OTHER_TEXT,'')::string as MATERIAL_TYPE_OTHER_TEXT,
    nullif(N.DATA:WITHDRAWN_DATE,'')::DATE as WITHDRAWN_DATE,
    nullif(N.DATA:WITHDRAWN_OTHER_REASON,'')::string as WITHDRAWN_OTHER_REASON,
    nullif(N.DATA:DECLARATION_ID,'')::string as DECLARATION_ID,
    nullif(N.DATA:DECLARED_BY,'')::string as DECLARED_BY,
    nullif(N.DATA:DECLARED_ON,'')::TIMESTAMP_NTZ as DECLARED_ON,
    N.DATA:SCHEME_KEY::string as SCHEME_KEY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N