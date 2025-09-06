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
    WHERE METADATA:"table-name"='PYMT_TRANSACTION_HEADERS' AND DATA is not null
)

SELECT
    N.DATA:PYMT_TRXN_HEADER_ID::bigint as PYMT_TRXN_HEADER_ID,
    nullif(N.DATA:BATCH_ID,'')::bigint as BATCH_ID,
    nullif(N.DATA:SCHEME,'')::string as SCHEME,
    nullif(N.DATA:LEGAL_ENTITY,'')::string as LEGAL_ENTITY,
    nullif(N.DATA:BUSINESS_UNIT,'')::string as BUSINESS_UNIT,
    nullif(N.DATA:PARTICIPANT_NUMBER,'')::string as PARTICIPANT_NUMBER,
    nullif(N.DATA:SITE_NUMBER,'')::string as SITE_NUMBER,
    nullif(N.DATA:TRANSACTION_TYPE,'')::string as TRANSACTION_TYPE,
    nullif(N.DATA:AMOUNT,'')::float as AMOUNT,
    nullif(N.DATA:PAYMENT_METHOD,'')::string as PAYMENT_METHOD,
    nullif(N.DATA:TAX_CLASSIFICATION,'')::string as TAX_CLASSIFICATION,
    nullif(N.DATA:ORIG_SYSTEM_REFERENCE,'')::string as ORIG_SYSTEM_REFERENCE,
    nullif(N.DATA:ORIG_REFERENCE_TYPE,'')::string as ORIG_REFERENCE_TYPE,
    nullif(N.DATA:CURRENCY_CODE,'')::string as CURRENCY_CODE,
    nullif(N.DATA:POS_TXN_NUM,'')::string as POS_TXN_NUM,
    nullif(N.DATA:PAY_REF_NUMBER,'')::bigint as PAY_REF_NUMBER,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:LAST_UPDATE_LOGIN,'')::string as LAST_UPDATE_LOGIN,
    nullif(N.DATA:PARTICIPANT_ID,'')::bigint as PARTICIPANT_ID,
    nullif(N.DATA:PARTICIPANT_SITE_ID,'')::bigint as PARTICIPANT_SITE_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:PAID,'')::string as PAID,
    nullif(N.DATA:INVOICED,'')::string as INVOICED,
    nullif(N.DATA:ERP_PAID,'')::string as ERP_PAID,
    nullif(N.DATA:VOIDED,'')::string as VOIDED,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N