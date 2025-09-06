{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PARTICREG_DOCUMENTS_UAT_S" if is_incremental() else "PARTICIPANTREGISTRATIONEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_uat()
    )
}}


WITH BM AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}

), BM_FLATTEN AS (

    SELECT 
        N.RECORD_CONTENT:registrationId::string  AS REGISTRATION_ID,
        N.RECORD_CONTENT:id::string||'-'||D.VALUE:documentId::string  ID,
        D.VALUE:documentId::string AS DOCUMENT_ID,
        D.VALUE:contentType::string AS CONTENT_TYPE,
        D.VALUE:documents:url::string as URL,
        D.VALUE:fileName::string AS FILE_NAME,
        N.RECORD_CONTENT:multiSchemeId::int AS MULTI_SCHEME_ID,
        N.RECORD_CONTENT:id::string AS KAFKA_ID,
        TO_TIMESTAMP(N.RECORD_CONTENT:time::string) AS KAFKA_DATETIME
    FROM 
        BM AS N,
        LATERAL FLATTEN(INPUT => N.RECORD_CONTENT:documents) AS D

)
select * from BM_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1 