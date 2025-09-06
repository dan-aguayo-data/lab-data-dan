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
    WHERE METADATA:"table-name"='PYMT_CONTROLS' AND DATA is not null
)

SELECT
    N.DATA:PYMT_CONTROL_ID::bigint as PYMT_CONTROL_ID,
    nullif(N.DATA:SCHEME_ID,'')::string as SCHEME_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:PAY_METHOD,'')::string as PAY_METHOD,
    N.DATA:CONTROL_CODE::string as CONTROL_CODE,
    N.DATA:CONTROL_DISP::string as CONTROL_DISP,
    nullif(N.DATA:CONTROL_DESC,'')::string as CONTROL_DESC,
    nullif(N.DATA:CONTROL_TYPE,'')::string as CONTROL_TYPE,
    nullif(N.DATA:TRANSACTION_VALUE,'')::bigint as TRANSACTION_VALUE,
    nullif(N.DATA:TRANSACTION_CNT,'')::bigint as TRANSACTION_CNT,
    nullif(N.DATA:TRANSACTION_QTY,'')::bigint as TRANSACTION_QTY,
    nullif(N.DATA:CRP_CNT,'')::bigint as CRP_CNT,
    nullif(N.DATA:POS_CNT,'')::bigint as POS_CNT,
    nullif(N.DATA:TIME_FACTOR,'')::string as TIME_FACTOR,
    nullif(N.DATA:TIME_RANGE,'')::bigint as TIME_RANGE,
    nullif(N.DATA:LOOKUP_CATEGORY,'')::string as LOOKUP_CATEGORY,
    nullif(N.DATA:MATCH_ON,'')::string as MATCH_ON,
    nullif(N.DATA:ACTIVE_FLAG,'')::string as ACTIVE_FLAG,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N