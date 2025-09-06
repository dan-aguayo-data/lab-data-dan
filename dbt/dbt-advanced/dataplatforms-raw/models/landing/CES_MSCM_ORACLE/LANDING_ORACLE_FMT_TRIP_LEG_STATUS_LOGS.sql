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
    WHERE METADATA:"table-name"='FMT_TRIP_LEG_STATUS_LOGS' AND DATA is not null
)

SELECT
    N.DATA:TRIP_LEG_STATUS_LOG_ID::bigint as TRIP_LEG_STATUS_LOG_ID,
    N.DATA:TRIP_LEG_ID::bigint as TRIP_LEG_ID,
    N.DATA:OLD_STATUS_ID::bigint as OLD_STATUS_ID,
    N.DATA:NEW_STATUS_ID::bigint as NEW_STATUS_ID,
    nullif(N.DATA:OLD_DISPLAY_STATUS_ID,'')::bigint as OLD_DISPLAY_STATUS_ID,
    nullif(N.DATA:NEW_DISPLAY_STATUS_ID,'')::bigint as NEW_DISPLAY_STATUS_ID,
    N.DATA:DATE_MODIFIED::TIMESTAMP_NTZ as DATE_MODIFIED,
    nullif(N.DATA:MODIFIED_BY,'')::string as MODIFIED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N