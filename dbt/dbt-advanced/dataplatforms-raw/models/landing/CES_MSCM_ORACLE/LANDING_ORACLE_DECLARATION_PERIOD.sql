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
    WHERE METADATA:"table-name"='DECLARATION_PERIOD' AND DATA is not null
)

SELECT
    N.DATA:DECLARATION_PERIOD_ID::bigint as DECLARATION_PERIOD_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    N.DATA:TYPE::string as TYPE,
    nullif(N.DATA:NAME,'')::string as NAME,
    N.DATA:START_DATE::TIMESTAMP_NTZ as START_DATE,
    nullif(N.DATA:END_DATE,'')::TIMESTAMP_NTZ as END_DATE,
    nullif(N.DATA:RELATED_PERIOD,'')::bigint as RELATED_PERIOD,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N