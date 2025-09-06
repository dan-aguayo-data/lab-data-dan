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
    WHERE METADATA:"table-name"='CONSUMER_REFUND_SERVICE_FEE' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:CONSUMER_REFUND_TXN_ID::string as CONSUMER_REFUND_TXN_ID,
    nullif(N.DATA:AGREEMENT_ID,'')::string as AGREEMENT_ID,
    nullif(N.DATA:AGREEMENT_NUMBER,'')::string as AGREEMENT_NUMBER,
    nullif(N.DATA:AGREEMENT_TYPE,'')::string as AGREEMENT_TYPE,
    nullif(N.DATA:AGREEMENT_RATE,'')::float as AGREEMENT_RATE,
    N.DATA:OVERRIDE_AMOUNT::float as OVERRIDE_AMOUNT,
    nullif(N.DATA:SERVICE_FEE,'')::float as SERVICE_FEE,
    nullif(N.DATA:SERVICE_FEE_TAX,'')::float as SERVICE_FEE_TAX,
    N.DATA:TOTAL_CONTAINER::bigint as TOTAL_CONTAINER,
    nullif(N.DATA:PARTNER_NUMBER,'')::string as PARTNER_NUMBER,
    nullif(N.DATA:PARTNER_NAME,'')::string as PARTNER_NAME,
    nullif(N.DATA:PARTNER_TYPE,'')::string as PARTNER_TYPE,
    nullif(N.DATA:CUSTOMER_ID,'')::string as CUSTOMER_ID,
    nullif(N.DATA:CUSTOMER_NUMBER,'')::string as CUSTOMER_NUMBER,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    N.DATA:VERSION::bigint as VERSION,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:ELIGIBLE_CONTAINER_COUNT,'')::bigint as ELIGIBLE_CONTAINER_COUNT,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N