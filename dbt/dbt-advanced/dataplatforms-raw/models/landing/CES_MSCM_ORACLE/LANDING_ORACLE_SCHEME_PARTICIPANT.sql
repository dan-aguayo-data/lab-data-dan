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
    WHERE METADATA:"table-name"='SCHEME_PARTICIPANT' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:SCHEME_ID::string as SCHEME_ID,
    N.DATA:NAME::string as NAME,
    nullif(N.DATA:TYPE,'')::string as TYPE,
    nullif(N.DATA:TAXONOMY_TYPE,'')::string as TAXONOMY_TYPE,
    nullif(N.DATA:TAXONOMY_SUB_TYPE,'')::string as TAXONOMY_SUB_TYPE,
    nullif(N.DATA:ABN,'')::string as ABN,
    nullif(N.DATA:ADDRESS_LINE_1,'')::string as ADDRESS_LINE_1,
    nullif(N.DATA:ADDRESS_LINE_2,'')::string as ADDRESS_LINE_2,
    nullif(N.DATA:SUBURB,'')::string as SUBURB,
    nullif(N.DATA:STATE_NAME,'')::string as STATE_NAME,
    nullif(N.DATA:POST_CODE,'')::string as POST_CODE,
    nullif(N.DATA:PHONE_NUMBER,'')::string as PHONE_NUMBER,
    nullif(N.DATA:BILL_TO_CUST_ACC_NUMBER,'')::string as BILL_TO_CUST_ACC_NUMBER,
    nullif(N.DATA:BILL_TO_CUST_SITE_NUMBER,'')::string as BILL_TO_CUST_SITE_NUMBER,
    nullif(N.DATA:SOLD_TO_CUST_ACC_NUMBER,'')::string as SOLD_TO_CUST_ACC_NUMBER,
    nullif(N.DATA:LEGAL_ENTITY_ID,'')::string as LEGAL_ENTITY_ID,
    nullif(N.DATA:LEGAL_ENTITY_NAME,'')::string as LEGAL_ENTITY_NAME,
    nullif(N.DATA:SUPPLIER_NAME,'')::string as SUPPLIER_NAME,
    nullif(N.DATA:SUPPLIER_NUMBER,'')::string as SUPPLIER_NUMBER,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:LEGAL_NAME,'')::string as LEGAL_NAME,
    nullif(N.DATA:TRADING_NAME,'')::string as TRADING_NAME,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N