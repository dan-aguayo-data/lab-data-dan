{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "PARTICREG_CONTACTS_S_D" if target.name.upper() == 'DEV' else "PARTICREG_CONTACTS_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "PARTICIPANTREGISTRATIONEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_prod()
    )
}}


WITH BM_CONTACT AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} s,
    LATERAL FLATTEN (input => parse_json(RECORD_CONTENT), path => 'contacts') f

), BM_HIST AS (
  
   SELECT
    MD5(REG.REGISTRATION_ID||'-'||REG.STATUS)||'-'||CON.EMAIL as ID 
  , CON.REGISTRATION_ID
  , CON.EMAIL
  , CON.FIRST_NAME
  , CON.LAST_NAME
  , CON.PHONE_NUMBER
  , CON.POSITION_TITLE
  , to_char(PHYS_ADDR.POSTCODE) as PHYS_ADDR_POSTCODE
  , PHYS_ADDR.STATE as PHYS_ADDR_STATE
  , PHYS_ADDR.STREET_ADDRESS as PHYS_ADDR_STREET_ADDRESS
  , PHYS_ADDR.SUBURB as PHYS_ADDR_SUBURB
  , 'Historic File' as SOURCE
  , decode(REG.STATUS, 'EMAIL_ADDED','au.com.ces.participant.registration.email.added.v1',
                      'ABN_ADDED','au.com.ces.participant.registration.abn.added.v1',
                      'COMPANY_DETAILS_ADDED','au.com.ces.participant.registration.company.details.added.v1',
                      'CONTACTS_ADDED','au.com.ces.participant.registration.contacts.added.v1',
                      'REVIEW_PENDING','au.com.ces.participant.registration.review.pending.v1',
                      'REVIEW_INFORMATION_REQUESTED','au.com.ces.participant.registration.review.information.rejected.v1',
                      'REVIEW_REJECTED','au.com.ces.participant.registration.review.rejected.v1',
                      'REVIEW_APPROVED','au.com.ces.participant.registration.approved.v1',
                      'PARTICIPANT_CREATED','au.com.ces.participant.registration.participant.created.v1',
    NULL) as TYPE
  , 10000 as MULTI_SCHEME_ID 
  , MD5(REG.REGISTRATION_ID||'-'||REG.STATUS) as KAFKA_ID   
  , CAST(CONVERT_TIMEZONE('UTC', CON.UPDATED_AT) AS TIMESTAMP) as UPDATED_AT
  from  
   {{ source('POSTGRES_MIGRATION_PROD', 'REGISTRATIONS') }} REG
  INNER JOIN {{ source('POSTGRES_MIGRATION_PROD', 'COMPANY_DETAILS') }} COMP
  ON COMP.REGISTRATION_ID=REG.REGISTRATION_ID
  LEFT JOIN {{ source('POSTGRES_MIGRATION_PROD', 'ADDRESSES') }} BUS_ADDR
  ON COMP.BUSINESS_ADDRESS_ID=BUS_ADDR.ADDRESS_ID
  LEFT JOIN {{ source('POSTGRES_MIGRATION_PROD', 'ADDRESSES') }} REG_ADDR
  ON COMP.REGISTERED_ADDRESS_ID=REG_ADDR.ADDRESS_ID
  LEFT JOIN {{ source('POSTGRES_MIGRATION_PROD', 'CONTACTS') }} CON
  ON CON.REGISTRATION_ID=REG.REGISTRATION_ID
  LEFT JOIN {{ source('POSTGRES_MIGRATION_PROD', 'ADDRESSES') }}  PHYS_ADDR
  ON CON.PHYSICAL_ADDRESS_ID=PHYS_ADDR.ADDRESS_ID


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

), BM_UNION AS ( 
    SELECT * FROM BM_FLATTEN 
    UNION ALL
    SELECT * FROM BM_HIST
  )
select * from BM_UNION
where NOT (upper(NVL(EMAIL,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM', '%PVT%'))
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1