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
    WHERE METADATA:"table-name"='PYMT_HOLDS' AND DATA is not null
)

SELECT
    N.DATA:HOLD_ID::bigint as HOLD_ID,
    N.DATA:APPROVAL_ID::bigint as APPROVAL_ID,
    nullif(N.DATA:PYMT_CONTROL_ID,'')::bigint as PYMT_CONTROL_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N