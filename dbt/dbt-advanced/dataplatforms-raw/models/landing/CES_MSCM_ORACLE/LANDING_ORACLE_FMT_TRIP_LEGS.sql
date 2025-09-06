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
    WHERE METADATA:"table-name"='FMT_TRIP_LEGS' AND DATA is not null
)

SELECT
    N.DATA:TRIP_LEG_ID::bigint as TRIP_LEG_ID,
    N.DATA:TRIP_ID::bigint as TRIP_ID,
    N.DATA:LEG_SEQUENCE::bigint as LEG_SEQUENCE,
    nullif(N.DATA:MANIFEST_NUMBER,'')::string as MANIFEST_NUMBER,
    nullif(N.DATA:PROVIDER_LEG_REF,'')::string as PROVIDER_LEG_REF,
    N.DATA:LEG_TYPE_ID::bigint as LEG_TYPE_ID,
    N.DATA:LEG_STATUS_ID::bigint as LEG_STATUS_ID,
    nullif(N.DATA:SCHEDULED_START,'')::DATE as SCHEDULED_START,
    nullif(N.DATA:SCHEDULED_END,'')::DATE as SCHEDULED_END,
    nullif(N.DATA:ACTUAL_START,'')::DATE as ACTUAL_START,
    nullif(N.DATA:ACTUAL_END,'')::DATE as ACTUAL_END,
    nullif(N.DATA:VEHICLE_ID,'')::bigint as VEHICLE_ID,
    nullif(N.DATA:DRIVER_ID,'')::bigint as DRIVER_ID,
    N.DATA:START_LOCATION_ID::bigint as START_LOCATION_ID,
    N.DATA:END_LOCATION_ID::bigint as END_LOCATION_ID,
    nullif(N.DATA:START_WEIGHT,'')::float as START_WEIGHT,
    nullif(N.DATA:END_WEIGHT,'')::float as END_WEIGHT,
    nullif(N.DATA:ACTUAL_DISTANCE_TRAVELLED,'')::bigint as ACTUAL_DISTANCE_TRAVELLED,
    nullif(N.DATA:SHIPPER_UNIT_STATUS,'')::string as SHIPPER_UNIT_STATUS,
    nullif(N.DATA:NOTES,'')::string as NOTES,
    nullif(N.DATA:CANCEL_REASON_ID,'')::bigint as CANCEL_REASON_ID,
    nullif(N.DATA:CANCEL_DATE,'')::DATE as CANCEL_DATE,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:ADJUST_REASON_ID,'')::bigint as ADJUST_REASON_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N