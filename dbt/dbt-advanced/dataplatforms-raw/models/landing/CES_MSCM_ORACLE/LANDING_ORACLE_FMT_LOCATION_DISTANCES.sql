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
    WHERE METADATA:"table-name"='FMT_LOCATION_DISTANCES' AND DATA is not null
)

SELECT
    N.DATA:FROM_LOCATION_ID::bigint as FROM_LOCATION_ID,
    N.DATA:TO_LOCATION_ID::bigint as TO_LOCATION_ID,
    N.DATA:PLAN_DISTANCE_KM::float as PLAN_DISTANCE_KM,
    N.DATA:PLAN_TIME_MINUTES::float as PLAN_TIME_MINUTES,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N