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
    WHERE METADATA:"table-name"='POS_DEVICE_HEARTBEAT' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:CRP_ID::string as CRP_ID,
    N.DATA:DEVICE_ID::string as DEVICE_ID,
    N.DATA:VERSION::string as VERSION,
    N.DATA:NAME::string as NAME,
    N.DATA:ENVIRONMENT::string as ENVIRONMENT,
    N.DATA:TYPE::string as TYPE,
    N.DATA:OS_VERSION::string as OS_VERSION,
    N.DATA:LONGITUDE::string as LONGITUDE,
    N.DATA:LATITUDE::string as LATITUDE,
    N.DATA:IP_ADDRESS::string as IP_ADDRESS,
    nullif(N.DATA:USER_DEFINED_1,'')::string as USER_DEFINED_1,
    nullif(N.DATA:USER_DEFINED_2,'')::string as USER_DEFINED_2,
    nullif(N.DATA:USER_DEFINED_3,'')::string as USER_DEFINED_3,
    nullif(N.DATA:USER_DEFINED_4,'')::string as USER_DEFINED_4,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_CRP_SITE_ID,'')::bigint as MSC_CRP_SITE_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N