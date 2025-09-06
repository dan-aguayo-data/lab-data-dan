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
    WHERE METADATA:"table-name"='SCHEME_PARTICIPANT_REL_DTL' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:SCHEME_PARTICIPANT_REL_ID::string as SCHEME_PARTICIPANT_REL_ID,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:EFFECTIVE_FROM::DATE as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::DATE as EFFECTIVE_TO,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N