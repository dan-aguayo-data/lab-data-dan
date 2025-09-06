
{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_", "") -%}
{%- set src_tbl = "PARTICIPANTCONTRACTEVENTTOPIC_S" if is_incremental() else "PARTICIPANTCONTRACTEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'CONTRACT_ID',
        enabled = run_flag_uat()
    )
}}

WITH source AS (
    SELECT
        *
     FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}
), JSON_FLATTEN AS (
    SELECT
        s.RECORD_CONTENT:id::string AS KAFKA_ID,
        s.RECORD_CONTENT:data:contractId::string AS CONTRACT_ID,
        s.RECORD_CONTENT:data:contractStatus::string AS CONTRACT_STATUS,
        s.RECORD_CONTENT:data:docusignStatus::string AS DOCUSIGN_STATUS,
        s.RECORD_CONTENT:data:envelopeId::string AS ENVELOPE_ID,
        s.RECORD_CONTENT:data:multiSchemeId::string AS MULTI_SCHEME_ID,
        s.RECORD_CONTENT:data:registrationId::string AS REGISTRATION_ID,
        COALESCE(s.RECORD_CONTENT:datetime::timestamp_ntz,s.RECORD_CONTENT:time::timestamp_ntz) AS KAFKA_DATETIME,
        s.RECORD_CONTENT:source::string AS SOURCE,
        s.RECORD_CONTENT:subject::string AS SUBJECT,
        s.RECORD_CONTENT:type::string AS TYPE
    FROM
        source AS s
)
SELECT *
FROM JSON_FLATTEN
QUALIFY row_number() OVER (PARTITION BY CONTRACT_ID ORDER BY KAFKA_DATETIME DESC) = 1