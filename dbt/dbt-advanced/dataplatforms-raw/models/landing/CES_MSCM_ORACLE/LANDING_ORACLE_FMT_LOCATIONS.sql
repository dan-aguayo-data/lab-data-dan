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
    WHERE METADATA:"table-name"='FMT_LOCATIONS' AND DATA is not null
)

SELECT
    N.DATA:LOCATION_ID::bigint as LOCATION_ID,
    N.DATA:LOCATION_NAME::string as LOCATION_NAME,
    N.DATA:LOCATION_TYPE_ID::bigint as LOCATION_TYPE_ID,
    N.DATA:SCHEME_LOCATION_NO::string as SCHEME_LOCATION_NO,
    N.DATA:ADDRESS::string as ADDRESS,
    nullif(N.DATA:AREA_ID,'')::bigint as AREA_ID,
    nullif(N.DATA:LOCAL_GOVERNMENT_AREA_ID,'')::bigint as LOCAL_GOVERNMENT_AREA_ID,
    nullif(N.DATA:REGION_ID,'')::bigint as REGION_ID,
    N.DATA:LATITUDE::float as LATITUDE,
    N.DATA:LONGITUDE::float as LONGITUDE,
    N.DATA:START_DATE_ACTIVE::DATE as START_DATE_ACTIVE,
    nullif(N.DATA:END_DATE_ACTIVE,'')::DATE as END_DATE_ACTIVE,
    nullif(N.DATA:OWNING_ORG_ID,'')::bigint as OWNING_ORG_ID,
    nullif(N.DATA:GEOFENCE_RADIUS,'')::float as GEOFENCE_RADIUS,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N