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
    WHERE METADATA:"table-name"='PYMT_CRM_STATUS' AND DATA is not null
)

SELECT
    N.DATA:PYMT_CRM_STATUS_ID::bigint as PYMT_CRM_STATUS_ID,
    N.DATA:PYMT_TRXN_HEADER_ID::bigint as PYMT_TRXN_HEADER_ID,
    nullif(N.DATA:PAYMENT_NUMBER,'')::string as PAYMENT_NUMBER,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:PARTICIPANT_ID,'')::bigint as PARTICIPANT_ID,
    nullif(N.DATA:PARTICIPANT_NUMBER,'')::string as PARTICIPANT_NUMBER,
    nullif(N.DATA:PAY_METHOD,'')::string as PAY_METHOD,
    nullif(N.DATA:FAILURE_REASON,'')::string as FAILURE_REASON,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:CRM_INCIDENT_ID,'')::string as CRM_INCIDENT_ID,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:UPDATED_ON::TIMESTAMP_NTZ as UPDATED_ON,
    N.DATA:UPDATED_BY::string as UPDATED_BY,
    nullif(N.DATA:REMINDER_COUNT,'')::bigint as REMINDER_COUNT,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N