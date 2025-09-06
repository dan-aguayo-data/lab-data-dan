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
    WHERE METADATA:"table-name"='MRF_VOLUME_DTL' AND DATA is not null
)

SELECT
    N.DATA:MRF_VOLUME_DTL_ID::string as MRF_VOLUME_DTL_ID,
    N.DATA:MRF_VOLUME_HDR_ID::string as MRF_VOLUME_HDR_ID,
    N.DATA:TRANSACTION_LINE_ID::string as TRANSACTION_LINE_ID,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    nullif(N.DATA:MRF_MATERIAL_TYPE_ID,'')::string as MRF_MATERIAL_TYPE_ID,
    N.DATA:UNITS::float as UNITS,
    nullif(N.DATA:KILOS,'')::float as KILOS,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N