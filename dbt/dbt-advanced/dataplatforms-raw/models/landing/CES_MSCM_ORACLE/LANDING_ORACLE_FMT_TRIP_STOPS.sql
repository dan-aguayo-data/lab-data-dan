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
    WHERE METADATA:"table-name"='FMT_TRIP_STOPS' AND DATA is not null
)

SELECT
    N.DATA:TRIP_STOP_ID::bigint as TRIP_STOP_ID,
    N.DATA:TRIP_ID::bigint as TRIP_ID,
    nullif(N.DATA:TRIP_LEG_ID,'')::bigint as TRIP_LEG_ID,
    N.DATA:STOP_TYPE_ID::bigint as STOP_TYPE_ID,
    N.DATA:START_TIME::DATE as START_TIME,
    nullif(N.DATA:END_TIME,'')::DATE as END_TIME,
    nullif(N.DATA:ADJUST_REASON_ID,'')::bigint as ADJUST_REASON_ID,
    nullif(N.DATA:NOTES,'')::string as NOTES,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N