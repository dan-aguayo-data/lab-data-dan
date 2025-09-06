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
    WHERE METADATA:"table-name"='PAYMENT_METADATA' AND DATA is not null
)

SELECT
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:SCHEME_PARTICIPANT_TYPE,'')::string as SCHEME_PARTICIPANT_TYPE,
    nullif(N.DATA:MODE_OF_PAYMENT,'')::string as MODE_OF_PAYMENT,
    nullif(N.DATA:TRANSACTION_TYPE,'')::string as TRANSACTION_TYPE,
    nullif(N.DATA:FREQUENCY,'')::string as FREQUENCY,
    nullif(N.DATA:INVOICE_TYPE,'')::string as INVOICE_TYPE,
    nullif(N.DATA:LEDGER,'')::string as LEDGER,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N