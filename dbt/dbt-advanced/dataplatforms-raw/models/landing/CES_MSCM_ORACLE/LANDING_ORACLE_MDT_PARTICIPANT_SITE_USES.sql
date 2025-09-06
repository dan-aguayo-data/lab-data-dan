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
    WHERE METADATA:"table-name"='MDT_PARTICIPANT_SITE_USES' AND DATA is not null
)

SELECT
    N.DATA:SITE_USE_ID::bigint as SITE_USE_ID,
    N.DATA:PARTICIPANT_SITE_ID::bigint as PARTICIPANT_SITE_ID,
    nullif(N.DATA:SITE_USE_TYPE,'')::string as SITE_USE_TYPE,
    nullif(N.DATA:COMMENTS,'')::string as COMMENTS,
    nullif(N.DATA:START_DATE_ACTIVE,'')::DATE as START_DATE_ACTIVE,
    nullif(N.DATA:END_DATE_ACTIVE,'')::DATE as END_DATE_ACTIVE,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:ERP_DATA_ACCESS_TYPE,'')::string as ERP_DATA_ACCESS_TYPE,
    nullif(N.DATA:ERP_DATA_ACCESS_VALUE,'')::string as ERP_DATA_ACCESS_VALUE,
    nullif(N.DATA:ERP_CUST_SITE_PURPOSE,'')::string as ERP_CUST_SITE_PURPOSE,
    nullif(N.DATA:ERP_SITE_PURCHASING,'')::string as ERP_SITE_PURCHASING,
    nullif(N.DATA:ERP_SITE_PAY,'')::string as ERP_SITE_PAY,
    nullif(N.DATA:ERP_ADD_ORDERING,'')::string as ERP_ADD_ORDERING,
    nullif(N.DATA:ERP_ADD_REMIT,'')::string as ERP_ADD_REMIT,
    nullif(N.DATA:ERP_ADD_RFQ_BID,'')::string as ERP_ADD_RFQ_BID,
    nullif(N.DATA:ERP_CUST_ACCT_SITE_ID,'')::bigint as ERP_CUST_ACCT_SITE_ID,
    nullif(N.DATA:ERP_VENDOR_SITE_ID,'')::bigint as ERP_VENDOR_SITE_ID,
    nullif(N.DATA:ERP_CUST_PROFILE_CLASS,'')::string as ERP_CUST_PROFILE_CLASS,
    N.DATA:SITE_PROFILE_CLASS::string as SITE_PROFILE_CLASS,
    nullif(N.DATA:SOLD_TO_CUST_ACC_NUMBER,'')::string as SOLD_TO_CUST_ACC_NUMBER,
    nullif(N.DATA:PO_PAY_ON_RECEIPT,'')::string as PO_PAY_ON_RECEIPT,
    nullif(N.DATA:INV_PAY_GROUP,'')::string as INV_PAY_GROUP,
    nullif(N.DATA:INV_TERM_DATE_BASIS,'')::string as INV_TERM_DATE_BASIS,
    nullif(N.DATA:INV_PAYMENT_TERMS,'')::string as INV_PAYMENT_TERMS,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N