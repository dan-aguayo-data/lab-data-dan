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
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_COEX') }}
    WHERE METADATA:"table-name"='FMT_SCHEME_VEHICLE_TYPES' AND DATA is not null
)

SELECT
    N.DATA:VEHICLE_TYPE_ID::bigint as VEHICLE_TYPE_ID,
    N.DATA:SCHEME_ID::bigint as SCHEME_ID,
    N.DATA:VEHICLE_TYPE_STATUS_ID::bigint as VEHICLE_TYPE_STATUS_ID,
    nullif(N.DATA:EFFECTIVE_DATE_FROM,'')::DATE as EFFECTIVE_DATE_FROM,
    nullif(N.DATA:EFFECTIVE_DATE_TO,'')::DATE as EFFECTIVE_DATE_TO,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N