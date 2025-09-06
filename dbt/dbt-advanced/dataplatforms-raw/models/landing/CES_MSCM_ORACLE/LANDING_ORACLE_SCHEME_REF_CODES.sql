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
    WHERE METADATA:"table-name"='SCHEME_REF_CODES' AND DATA is not null
)

SELECT
    N.DATA:SCHEME_REF_CODES_ID::bigint as SCHEME_REF_CODES_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:CATEGORY::string as CATEGORY,
    N.DATA:CODE::string as CODE,
    nullif(N.DATA:VALUE,'')::string as VALUE,
    nullif(N.DATA:DESCRIPTION,'')::string as DESCRIPTION,
    N.DATA:EFFECTIVE_FROM::TIMESTAMP_NTZ as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::TIMESTAMP_NTZ as EFFECTIVE_TO,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    N.DATA:ROW_EDITING_ENABLED::string as ROW_EDITING_ENABLED,
    N.DATA:ROW_DISPLAY_ENABLED::string as ROW_DISPLAY_ENABLED,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N