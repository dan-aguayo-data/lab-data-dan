{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PARTICREG_CONTACTS_ROLE_UAT_S" if is_incremental() else "PARTICIPANTREGISTRATIONEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_uat()
    )
}}


WITH BM_CONTACT_ROLES AS (

    SELECT s.*, f.*, g.VALUE as ROLE_NAME
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }} s,
    LATERAL FLATTEN (input => s.RECORD_CONTENT:contacts) f,
    LATERAL FLATTEN (input => f.VALUE:roles) g

), BM_FLATTEN AS (
  
SELECT 
      N.RECORD_CONTENT:id::string||'-'||N.VALUE:email::string||'-'||N.ROLE_NAME::string as ID 
    , N.RECORD_CONTENT:registrationId::string as REGISTRATION_ID  
    , N.VALUE:email::string EMAIL
    , N.ROLE_NAME::string as ROLE_NAME
    , N.RECORD_CONTENT:source::string as SOURCE
    , N.RECORD_CONTENT:type::string as TYPE
    , N.RECORD_CONTENT:multiSchemeId::int AS MULTI_SCHEME_ID  
    , N.RECORD_CONTENT:id::string as KAFKA_ID  
    , TO_TIMESTAMP(N.RECORD_CONTENT:time::string) as KAFKA_DATETIME
    FROM 
    BM_CONTACT_ROLES as N

)
select * from BM_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1

