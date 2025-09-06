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
    WHERE METADATA:"table-name"='REFUND_TXN_SURVEY' AND DATA is not null
)

SELECT
    N.DATA:REFUND_TXN_SURVEY_ID::bigint as REFUND_TXN_SURVEY_ID,
    nullif(N.DATA:SURVEY_TYPE,'')::string as SURVEY_TYPE,
    nullif(N.DATA:VALUE,'')::string as VALUE,
    N.DATA:REFUND_TXN_ID::string as REFUND_TXN_ID,
    N.DATA:REFUND_TXN_TYPE::string as REFUND_TXN_TYPE,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N