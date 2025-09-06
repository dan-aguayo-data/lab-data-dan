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
    WHERE METADATA:"table-name"='FMT_VEHICLE_TYPES' AND DATA is not null
)

SELECT
    N.DATA:VEHICLE_TYPE_ID::bigint as VEHICLE_TYPE_ID,
    N.DATA:VEHICLE_TYPE_NAME::string as VEHICLE_TYPE_NAME,
    nullif(N.DATA:MAKE,'')::string as MAKE,
    nullif(N.DATA:MODEL_NAME,'')::string as MODEL_NAME,
    nullif(N.DATA:GVM,'')::bigint as GVM,
    nullif(N.DATA:PAYLOAD,'')::float as PAYLOAD,
    nullif(N.DATA:NO_OF_AXLES,'')::bigint as NO_OF_AXLES,
    nullif(N.DATA:CONFIGURATION,'')::string as CONFIGURATION,
    N.DATA:START_DATE_ACTIVE::DATE as START_DATE_ACTIVE,
    nullif(N.DATA:END_DATE_ACTIVE,'')::DATE as END_DATE_ACTIVE,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N