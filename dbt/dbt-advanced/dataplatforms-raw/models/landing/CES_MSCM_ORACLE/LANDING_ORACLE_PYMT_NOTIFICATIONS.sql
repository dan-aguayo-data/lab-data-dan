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
    WHERE METADATA:"table-name"='PYMT_NOTIFICATIONS' AND DATA is not null
)

SELECT
    N.DATA:NOTIFICATION_ID::bigint as NOTIFICATION_ID,
    N.DATA:APPROVAL_ID::bigint as APPROVAL_ID,
    N.DATA:NOTIFICATION_TYPE::string as NOTIFICATION_TYPE,
    nullif(N.DATA:APPROVAL_STATUS,'')::string as APPROVAL_STATUS,
    nullif(N.DATA:COMMENTS,'')::string as COMMENTS,
    N.DATA:ASSIGNED_TO::string as ASSIGNED_TO,
    nullif(N.DATA:APP_ORDER,'')::bigint as APP_ORDER,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    nullif(N.DATA:PCS_ID,'')::string as PCS_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N