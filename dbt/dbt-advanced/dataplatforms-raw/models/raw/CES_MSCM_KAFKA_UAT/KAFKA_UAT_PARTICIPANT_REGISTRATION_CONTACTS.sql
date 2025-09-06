{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PARTICREG_CONTACTS_UAT_S" if is_incremental() else "PARTICIPANTREGISTRATIONEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_uat()
    )
}}


WITH BM_CONTACT AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }} s,
    LATERAL FLATTEN (input => parse_json(RECORD_CONTENT), path => 'contacts') f

), BM_FLATTEN AS (
  
SELECT 
      N.RECORD_CONTENT:id::string||'-'||N.VALUE:email::string as ID 
    , N.RECORD_CONTENT:registrationId::string as REGISTRATION_ID  
    , N.VALUE:email::string EMAIL
    , N.VALUE:firstName::string FIRST_NAME
    , N.VALUE:lastName::string LAST_NAME
    , N.VALUE:phoneNumber::string PHONE_NUMBER
    , N.VALUE:positionTitle::string POSITION_TITLE
    , N.VALUE:physicalAddress:postcode::string PHYS_ADDR_POSTCODE
    , N.VALUE:physicalAddress:state::string PHYS_ADDR_STATE
    , N.VALUE:physicalAddress:streetAddress::string PHYS_ADDR_STREET_ADDRESS
    , N.VALUE:physicalAddress:suburb::string PHYS_ADDR_SUBURB
    , N.RECORD_CONTENT:source::string as SOURCE
    , N.RECORD_CONTENT:type::string as TYPE
    , N.RECORD_CONTENT:multiSchemeId::int AS MULTI_SCHEME_ID  
    , N.RECORD_CONTENT:id::string as KAFKA_ID  
    , TO_TIMESTAMP(N.RECORD_CONTENT:time::string) as KAFKA_DATETIME
    FROM 
    BM_CONTACT as N

)
select * from BM_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1