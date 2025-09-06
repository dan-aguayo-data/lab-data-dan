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
    WHERE METADATA:"table-name"='MDT_CUSTOMER_UUID' AND DATA is not null
)

SELECT
    N.DATA:ID::bigint as ID,
    nullif(N.DATA:CONSUMER_NUMBER,'')::string as CONSUMER_NUMBER,
    nullif(N.DATA:CUSTOMER_UUID,'')::string as CUSTOMER_UUID,
    nullif(N.DATA:MARKETING_UUID,'')::string as MARKETING_UUID,
    nullif(N.DATA:SERVICEDESK_UUID,'')::string as SERVICEDESK_UUID,
    nullif(N.DATA:USER_TYPE,'')::string as USER_TYPE,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    nullif(N.DATA:LAST_MODIFIED_ON,'')::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:LAST_MODIFIED_BY,'')::string as LAST_MODIFIED_BY,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N