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
    WHERE METADATA:"table-name"='FMT_TRIP_UNITS' AND DATA is not null
)

SELECT
    N.DATA:TRIP_UNIT_ID::bigint as TRIP_UNIT_ID,
    N.DATA:TRIP_LEG_ID::bigint as TRIP_LEG_ID,
    N.DATA:MANIFEST_NUMBER::string as MANIFEST_NUMBER,
    nullif(N.DATA:SHIPPER_UNIT_TYPE_ID,'')::bigint as SHIPPER_UNIT_TYPE_ID,
    nullif(N.DATA:NO_OF_CONTAINERS,'')::bigint as NO_OF_CONTAINERS,
    nullif(N.DATA:UNIT_WEIGHT_START,'')::float as UNIT_WEIGHT_START,
    nullif(N.DATA:UNIT_WEIGHT_END,'')::float as UNIT_WEIGHT_END,
    nullif(N.DATA:MATERIAL_TYPE_ID,'')::string as MATERIAL_TYPE_ID,
    nullif(N.DATA:SHIPPER_UNIT_QTY,'')::bigint as SHIPPER_UNIT_QTY,
    nullif(N.DATA:SHIPPER_UNIT_REF,'')::string as SHIPPER_UNIT_REF,
    nullif(N.DATA:ADJUST_REASON_ID,'')::bigint as ADJUST_REASON_ID,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N