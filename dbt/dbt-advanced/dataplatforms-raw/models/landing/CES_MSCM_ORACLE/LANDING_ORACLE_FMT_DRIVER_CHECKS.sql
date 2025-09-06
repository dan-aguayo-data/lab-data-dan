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
    WHERE METADATA:"table-name"='FMT_DRIVER_CHECKS' AND DATA is not null
)

SELECT
    N.DATA:DRIVER_CHECK_ID::bigint as DRIVER_CHECK_ID,
    N.DATA:DRIVER_ID::bigint as DRIVER_ID,
    nullif(N.DATA:VEHICLE_ID,'')::bigint as VEHICLE_ID,
    N.DATA:CHECK_TYPE_ID::bigint as CHECK_TYPE_ID,
    N.DATA:CHECK_DATE::DATE as CHECK_DATE,
    nullif(N.DATA:NOTES,'')::string as NOTES,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:CHECK_CONTENTS,'')::string as CHECK_CONTENTS,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N