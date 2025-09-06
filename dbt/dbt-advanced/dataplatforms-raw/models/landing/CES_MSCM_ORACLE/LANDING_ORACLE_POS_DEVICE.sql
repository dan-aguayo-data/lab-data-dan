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
    WHERE METADATA:"table-name"='POS_DEVICE' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:CRP_ID::string as CRP_ID,
    nullif(N.DATA:IDCS_APPLICATION_ID,'')::string as IDCS_APPLICATION_ID,
    N.DATA:NAME::string as NAME,
    N.DATA:TYPE::string as TYPE,
    N.DATA:STATUS::string as STATUS,
    nullif(N.DATA:SYNCED,'')::bigint as SYNCED,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_CRP_SITE_ID,'')::bigint as MSC_CRP_SITE_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N