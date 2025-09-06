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
    WHERE METADATA:"table-name"='MFG_STAT_DEC_PERIOD_DTL' AND DATA is not null
)

SELECT
    N.DATA:MFG_STAT_DEC_PERIOD_DTL_ID::bigint as MFG_STAT_DEC_PERIOD_DTL_ID,
    N.DATA:MFG_STAT_DEC_PERIOD_HDR_ID::bigint as MFG_STAT_DEC_PERIOD_HDR_ID,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    N.DATA:UOM::string as UOM,
    N.DATA:VOLUME::float as VOLUME,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N