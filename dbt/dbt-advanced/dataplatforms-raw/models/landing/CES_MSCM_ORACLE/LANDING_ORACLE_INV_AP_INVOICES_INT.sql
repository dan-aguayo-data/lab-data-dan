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
    WHERE METADATA:"table-name"='INV_AP_INVOICES_INT' AND DATA is not null
)

SELECT
    N.DATA:AP_INVOICE_INT_ID::bigint as AP_INVOICE_INT_ID,
    nullif(N.DATA:BUSINESS_UNIT,'')::string as BUSINESS_UNIT,
    nullif(N.DATA:DESCRIPTION,'')::string as DESCRIPTION,
    nullif(N.DATA:INVOICE_AMOUNT,'')::float as INVOICE_AMOUNT,
    nullif(N.DATA:INVOICE_CURRENCY,'')::string as INVOICE_CURRENCY,
    nullif(N.DATA:INVOICE_DATE,'')::DATE as INVOICE_DATE,
    nullif(N.DATA:INVOICE_NUMBER,'')::string as INVOICE_NUMBER,
    nullif(N.DATA:INVOICE_SOURCE,'')::string as INVOICE_SOURCE,
    nullif(N.DATA:LEGAL_ENTITY,'')::string as LEGAL_ENTITY,
    nullif(N.DATA:PAY_GROUP,'')::string as PAY_GROUP,
    nullif(N.DATA:PAYMENT_METHOD,'')::string as PAYMENT_METHOD,
    nullif(N.DATA:PAYMENT_TERMS,'')::string as PAYMENT_TERMS,
    nullif(N.DATA:SUPPLIER_ID,'')::string as SUPPLIER_ID,
    nullif(N.DATA:SUPPLIER_NAME,'')::string as SUPPLIER_NAME,
    nullif(N.DATA:SUPPLIER_NUMBER,'')::string as SUPPLIER_NUMBER,
    nullif(N.DATA:SUPPLIER_SITE_ID,'')::string as SUPPLIER_SITE_ID,
    nullif(N.DATA:SUPPLIER_SITE_NUMBER,'')::string as SUPPLIER_SITE_NUMBER,
    nullif(N.DATA:SUPPLIER_SITE_NAME,'')::string as SUPPLIER_SITE_NAME,
    nullif(N.DATA:DUE_DATE,'')::DATE as DUE_DATE,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:ERP_BANK_ACCOUNT_ID,'')::string as ERP_BANK_ACCOUNT_ID,
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
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    nullif(N.DATA:ORIG_HEADER_ID,'')::bigint as ORIG_HEADER_ID,
    nullif(N.DATA:ORIG_TYPE,'')::string as ORIG_TYPE,
    nullif(N.DATA:CANCELLED_FLAG,'')::string as CANCELLED_FLAG,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N