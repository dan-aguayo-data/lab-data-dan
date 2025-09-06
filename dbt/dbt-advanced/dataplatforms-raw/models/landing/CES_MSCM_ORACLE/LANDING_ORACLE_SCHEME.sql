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
    WHERE METADATA:"table-name"='SCHEME' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:NAME::string as NAME,
    nullif(N.DATA:LOCATION,'')::string as LOCATION,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:TIMEZONE,'')::string as TIMEZONE,
    N.DATA:PREFIX::string as PREFIX,
    nullif(N.DATA:COMMENCE_DATE,'')::DATE as COMMENCE_DATE,
    nullif(N.DATA:PARENT_ID,'')::bigint as PARENT_ID,
    N.DATA:ENTITY_TYPE::string as ENTITY_TYPE,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N