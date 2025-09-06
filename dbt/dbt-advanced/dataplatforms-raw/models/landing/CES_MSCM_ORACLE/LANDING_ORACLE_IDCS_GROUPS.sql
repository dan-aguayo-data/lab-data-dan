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
    WHERE METADATA:"table-name"='IDCS_GROUPS' AND DATA is not null
)

SELECT
    N.DATA:IDCS_GROUP_ID::string as IDCS_GROUP_ID,
    N.DATA:NAME::string as NAME,
    N.DATA:IDCS_SYNCED::bigint as IDCS_SYNCED,
    N.DATA:LAST_IDCS_SYNCED_ON::TIMESTAMP_NTZ as LAST_IDCS_SYNCED_ON,
    N.DATA:STATUS::string as STATUS,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N