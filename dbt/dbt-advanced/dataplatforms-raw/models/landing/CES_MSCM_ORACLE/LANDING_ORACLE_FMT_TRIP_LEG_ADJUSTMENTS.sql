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
    WHERE METADATA:"table-name"='FMT_TRIP_LEG_ADJUSTMENTS' AND DATA is not null
)

SELECT
    N.DATA:TRIP_LEG_ADJUSTMENT_ID::bigint as TRIP_LEG_ADJUSTMENT_ID,
    nullif(N.DATA:TRIP_LEG_ID,'')::bigint as TRIP_LEG_ID,
    nullif(N.DATA:ADJUSTMENT_SEQ,'')::bigint as ADJUSTMENT_SEQ,
    nullif(N.DATA:OLD_MANIFEST_NUMBER,'')::string as OLD_MANIFEST_NUMBER,
    nullif(N.DATA:NEW_MANIFEST_NUMBER,'')::string as NEW_MANIFEST_NUMBER,
    nullif(N.DATA:OLD_ACTUAL_START,'')::DATE as OLD_ACTUAL_START,
    nullif(N.DATA:NEW_ACTUAL_START,'')::DATE as NEW_ACTUAL_START,
    nullif(N.DATA:OLD_ACTUAL_END,'')::DATE as OLD_ACTUAL_END,
    nullif(N.DATA:NEW_ACTUAL_END,'')::DATE as NEW_ACTUAL_END,
    nullif(N.DATA:OLD_VEHICLE_ID,'')::bigint as OLD_VEHICLE_ID,
    nullif(N.DATA:NEW_VEHICLE_ID,'')::bigint as NEW_VEHICLE_ID,
    nullif(N.DATA:OLD_DRIVER_ID,'')::bigint as OLD_DRIVER_ID,
    nullif(N.DATA:NEW_DRIVER_ID,'')::bigint as NEW_DRIVER_ID,
    nullif(N.DATA:ADJUST_REASON_ID,'')::bigint as ADJUST_REASON_ID,
    nullif(N.DATA:NOTES,'')::string as NOTES,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N