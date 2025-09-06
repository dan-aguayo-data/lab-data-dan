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
    WHERE METADATA:"table-name"='SS_AUDIT_ADJUSTMENTS' AND DATA is not null
)

SELECT
    N.DATA:SS_AUDIT_ADJUSTMENT_ID::bigint as SS_AUDIT_ADJUSTMENT_ID,
    N.DATA:PARTICIPANT_SITE_ID::bigint as PARTICIPANT_SITE_ID,
    N.DATA:ADJUSTER_ID::string as ADJUSTER_ID,
    N.DATA:REASON_ID::bigint as REASON_ID,
    N.DATA:COMMENTS::string as COMMENTS,
    nullif(N.DATA:APPROVER_ID,'')::string as APPROVER_ID,
    nullif(N.DATA:APPROVER_COMMENTS,'')::string as APPROVER_COMMENTS,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    N.DATA:MULTI_SCHEME_ID::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N