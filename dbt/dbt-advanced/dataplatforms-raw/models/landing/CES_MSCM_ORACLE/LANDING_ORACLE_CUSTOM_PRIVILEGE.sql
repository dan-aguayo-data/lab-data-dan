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
    WHERE METADATA:"table-name"='CUSTOM_PRIVILEGE' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:ROLE_ID,'')::string as ROLE_ID,
    nullif(N.DATA:CUSTOM_DOMAIN,'')::string as CUSTOM_DOMAIN,
    nullif(N.DATA:CUSTOM_RESOURCE,'')::string as CUSTOM_RESOURCE,
    nullif(N.DATA:CUSTOM_ACTION,'')::string as CUSTOM_ACTION,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:ACTIVE_FLAG::string as ACTIVE_FLAG,
    N.DATA:ROW_EDITING_ENABLED::string as ROW_EDITING_ENABLED,
    N.DATA:ROW_DISPLAY_ENABLED::string as ROW_DISPLAY_ENABLED,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N