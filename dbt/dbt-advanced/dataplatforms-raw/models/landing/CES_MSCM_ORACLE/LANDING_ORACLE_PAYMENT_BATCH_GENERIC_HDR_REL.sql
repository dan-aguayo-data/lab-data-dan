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
    WHERE METADATA:"table-name"='PAYMENT_BATCH_GENERIC_HDR_REL' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:PAYMENT_BATCH_ID,'')::string as PAYMENT_BATCH_ID,
    nullif(N.DATA:SCHEME_PARTICIPANT_ID,'')::string as SCHEME_PARTICIPANT_ID,
    nullif(N.DATA:TXN_HEADER_ID,'')::string as TXN_HEADER_ID,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N