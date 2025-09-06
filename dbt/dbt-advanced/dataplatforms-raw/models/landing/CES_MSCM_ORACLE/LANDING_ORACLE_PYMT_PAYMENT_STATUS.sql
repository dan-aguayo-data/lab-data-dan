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
    WHERE METADATA:"table-name"='PYMT_PAYMENT_STATUS' AND DATA is not null
)

SELECT
    N.DATA:PAYMENT_STATUS_ID::bigint as PAYMENT_STATUS_ID,
    N.DATA:PYMT_TRXN_HEADER_ID::bigint as PYMT_TRXN_HEADER_ID,
    N.DATA:STATUS::string as STATUS,
    N.DATA:PAY_METHOD::string as PAY_METHOD,
    nullif(N.DATA:REQ_APPROVAL_FLAG,'')::string as REQ_APPROVAL_FLAG,
    nullif(N.DATA:CLOSED_FLAG,'')::string as CLOSED_FLAG,
    nullif(N.DATA:CANCELLED_FLAG,'')::string as CANCELLED_FLAG,
    nullif(N.DATA:EFFECTIVE_FROM,'')::TIMESTAMP_NTZ as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::TIMESTAMP_NTZ as EFFECTIVE_TO,
    nullif(N.DATA:ERP_ACCOUNT_ID,'')::string as ERP_ACCOUNT_ID,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:ACTIVE_FLAG,'')::string as ACTIVE_FLAG,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N