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
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM') }}
    WHERE METADATA:"table-name"='MDT_SHIPPER_UNIT_TYPES_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:SHIPPER_UNIT_TYPE_ID,'')::bigint as SHIPPER_UNIT_TYPE_ID,
    nullif(N.DATA:PROCESSOR_SITE_ID,'')::bigint as PROCESSOR_SITE_ID,
    nullif(N.DATA:SHIPPER_UNIT_TYPE,'')::string as SHIPPER_UNIT_TYPE,
    nullif(N.DATA:EMPTY_WEIGHT,'')::float as EMPTY_WEIGHT,
    nullif(N.DATA:VOLUME,'')::float as VOLUME,
    nullif(N.DATA:EFFECTIVE_FROM,'')::DATE as EFFECTIVE_FROM,
    nullif(N.DATA:EFFECTIVE_TO,'')::DATE as EFFECTIVE_TO,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:QUANTITY,'')::bigint as QUANTITY,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N