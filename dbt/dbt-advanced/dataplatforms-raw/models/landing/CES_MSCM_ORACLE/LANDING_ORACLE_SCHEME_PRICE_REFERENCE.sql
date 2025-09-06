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
    WHERE METADATA:"table-name"='SCHEME_PRICE_REFERENCE' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:SCHEME_ID,'')::string as SCHEME_ID,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    N.DATA:SCHEME_PRICE::float as SCHEME_PRICE,
    N.DATA:EFFECTIVE_FROM::DATE as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::DATE as EFFECTIVE_TO,
    nullif(N.DATA:SCHEME_PARTICIPANT_ID,'')::string as SCHEME_PARTICIPANT_ID,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_PARTICIPANT_SITE_ID,'')::bigint as MSC_PARTICIPANT_SITE_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N