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
    WHERE METADATA:"table-name"='IDCS_GROUPS_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:IDCS_GROUP_ID,'')::string as IDCS_GROUP_ID,
    nullif(N.DATA:NAME,'')::string as NAME,
    nullif(N.DATA:IDCS_SYNCED,'')::bigint as IDCS_SYNCED,
    nullif(N.DATA:LAST_IDCS_SYNCED_ON,'')::TIMESTAMP_NTZ as LAST_IDCS_SYNCED_ON,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N