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
    WHERE METADATA:"table-name"='PYMT_BATCHES_ALL' AND DATA is not null
)

SELECT
    N.DATA:BATCH_ID::bigint as BATCH_ID,
    nullif(N.DATA:BATCH_NAME,'')::string as BATCH_NAME,
    nullif(N.DATA:BATCH_STATUS,'')::string as BATCH_STATUS,
    nullif(N.DATA:PAYMENT_METHOD,'')::string as PAYMENT_METHOD,
    nullif(N.DATA:BATCH_DATE,'')::DATE as BATCH_DATE,
    nullif(N.DATA:BATCH_COUNT,'')::bigint as BATCH_COUNT,
    nullif(N.DATA:BATCH_AMOUNT,'')::float as BATCH_AMOUNT,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:LAST_UPDATE_LOGIN,'')::string as LAST_UPDATE_LOGIN,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:THIRD_PARTY_PAYMENT_REF,'')::string as THIRD_PARTY_PAYMENT_REF,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N