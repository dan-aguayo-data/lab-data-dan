{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "PARTICREG_S_D" if target.name.upper() == 'DEV' else "PARTICREG_S_P" -%}
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


WITH BM AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }}

), BM_HIST AS (

  select 
    REG.REGISTRATION_ID||'-'||REG.STATUS as ID
  , REG.ABN as REG_ABN
  , CAST(CONVERT_TIMEZONE('UTC', REG.CONTRACT_EXECUTED_AT) AS TIMESTAMP) as REG_CONTRACT_EXECUTED_AT
  , REG.EMAIL as REG_EMAIL
  , CAST(CONVERT_TIMEZONE('UTC', REG.LAST_REVIEWED_AT) AS TIMESTAMP) as REG_LAST_REVIEWED_AT
  , REG.LAST_REVIEWED_BY as REG_LAST_REVIEWED_BY
  , CAST(CONVERT_TIMEZONE('UTC', REG.PARTICIPANT_CREATED_AT) AS TIMESTAMP) as REG_PARTICIPANT_CREATED_AT
  , REG.REGISTRATION_ID as REG_REGISTRATION_ID
  , REG.STATUS as REG_STATUS
  , REG.REVIEW_COMMENT_TEXT as REG_REVIEW_COMMENT_TEXT
  , NULL AS ACCEPTED_PRIVACY_POLICY
  , CAST(CONVERT_TIMEZONE('UTC', REG.SUBMITTED_AT) AS TIMESTAMP) as REG_SUBMITTED_AT
  , COMP.ABN
  , COMP.ACN
  , COMP.BEVERAGE_MANUFACTURER_SIZE
  , COMP.ENTITY_NAME
  , COMP.ENTITY_TYPE
  , COMP.ENTITY_TYPE_CODE
  , COMP.GST_REGISTERED_FROM
  , COMP.INVOICE_FREQUENCY
  , COMP.IS_SOLE_DIRECTOR
  , COMP.MANUFACTURES_ONLY_WINE_OR_SPIRITS
  , COMP.TRADING_NAME
  , to_char(BUS_ADDR.POSTCODE) as BUS_ADDR_POSTCODE
  , BUS_ADDR.STATE as BUS_ADDR_STATE
  , BUS_ADDR.STREET_ADDRESS as BUS_ADDR_STREET_ADDRESS
  , BUS_ADDR.SUBURB as BUS_ADDR_SUBURB
  , to_char(REG_ADDR.POSTCODE) as REG_ADDR_POSTCODE
  , REG_ADDR.STATE as REG_ADDR_STATE
  , REG_ADDR.STREET_ADDRESS as REG_ADDR_STREET_ADDRESS
  , REG_ADDR.SUBURB as REG_ADDR_SUBURB
  , 10000 as MULTI_SCHEME_ID
  , NULL as PARTICIPANT_ID
  , NULL as PARTICIPANT_NUMBER
  , CAST(CONVERT_TIMEZONE('UTC', REG.SUBMITTED_AT) AS TIMESTAMP) as SUBMITTED_AT
  , REG.REGISTRATION_ID as REGISTRATION_ID
  , REG.STATUS as STATUS
  , NULL as TRUST_NAME
  , NULL as CORPORATE_TRUSTEE
  , NULL as BUSINESS_REG_NUMBER
  , 'Historic File' as SOURCE
  , NULL as SUBJECT
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
  , decode(REG.STATUS, 'EMAIL_ADDED',1,
                      'ABN_ADDED',2,
                      'COMPANY_DETAILS_ADDED', 3,
                      'CONTACTS_ADDED', 4,
                      'REVIEW_PENDING', 5,
                      'REVIEW_INFORMATION_REQUESTED', 6,
                      'REVIEW_REJECTED', 7,
                      'REVIEW_APPROVED', 8,
                      'PARTICIPANT_CREATED', 9,
    99) as TYPE_ORDER
  , MD5(REG.REGISTRATION_ID||'-'||REG.STATUS) as KAFKA_ID
  , to_timestamp('2023-07-01 00:00:00.000') as KAFKA_DATETIME
  from  
  {{ source('POSTGRES_MIGRATION_PROD', 'REGISTRATIONS') }} REG
  INNER JOIN {{ source('POSTGRES_MIGRATION_PROD', 'COMPANY_DETAILS') }} COMP
  ON COMP.REGISTRATION_ID=REG.REGISTRATION_ID
  LEFT JOIN {{ source('POSTGRES_MIGRATION_PROD', 'ADDRESSES') }} BUS_ADDR
  ON COMP.BUSINESS_ADDRESS_ID=BUS_ADDR.ADDRESS_ID
  LEFT JOIN {{ source('POSTGRES_MIGRATION_PROD', 'ADDRESSES') }} REG_ADDR
  ON COMP.REGISTERED_ADDRESS_ID=REG_ADDR.ADDRESS_ID
  
), BM_FLATTEN AS (

SELECT 
      N.RECORD_CONTENT:registrationId::string||'-'||N.RECORD_CONTENT:registrationStatus::string as ID
    , N.RECORD_CONTENT:registration:abn::string as REG_ABN
    , TO_TIMESTAMP(N.RECORD_CONTENT:registration:contractExecutedAt::string, 'DD/MM/YY') as REG_CONTRACT_EXECUTED_AT
    , N.RECORD_CONTENT:registration:emailId::string as REG_EMAIL
    , TO_TIMESTAMP(N.RECORD_CONTENT:registration:lastReviewedAt::string, 'DD/MM/YY') as REG_LAST_REVIEWED_AT
    , N.RECORD_CONTENT:registration:lastReviewedBy::string as REG_LAST_REVIEWED_BY
    , TO_TIMESTAMP(N.RECORD_CONTENT:registration:participantCreatedAt::string, 'DD/MM/YY') as REG_PARTICIPANT_CREATED_AT
    , N.RECORD_CONTENT:registration:registrationId::string as REG_REGISTRATION_ID
    , N.RECORD_CONTENT:registration:registrationStatus::string as REG_STATUS  
    , N.RECORD_CONTENT:registration:reviewCommentText::string as REG_REVIEW_COMMENT_TEXT
    , N.RECORD_CONTENT:registration:acceptedPrivacyPolicy::string as ACCEPTED_PRIVACY_POLICY  
    , TO_TIMESTAMP(N.RECORD_CONTENT:registration:submittedAt::string, 'DD/MM/YY') as REG_SUBMITTED_AT   
    , N.RECORD_CONTENT:companyDetails:abn::string as ABN
    , N.RECORD_CONTENT:companyDetails:acn::string as ACN
    , N.RECORD_CONTENT:companyDetails:beverageManufacturerSize::string as BEVERAGE_MANUFACTURER_SIZE
    , N.RECORD_CONTENT:companyDetails:entityName::string as ENTITY_NAME
    , N.RECORD_CONTENT:companyDetails:entityType::string as ENTITY_TYPE
    , N.RECORD_CONTENT:companyDetails:entityTypeCode::string as ENTITY_TYPE_CODE
    , TO_DATE(NULLIF(N.RECORD_CONTENT:companyDetails:gstRegisteredFrom::string,''), 'DD MON YYYY') as GST_REGISTERED_FROM
    , N.RECORD_CONTENT:companyDetails:invoiceFrequency::string as INVOICE_FREQUENCY
    , N.RECORD_CONTENT:companyDetails:isSoleDirector::string as IS_SOLE_DIRECTOR
    , N.RECORD_CONTENT:companyDetails:manufacturesOnlyWineOrSpirits::string as MANUFACTURES_ONLY_WINE_OR_SPIRITS
    , N.RECORD_CONTENT:companyDetails:tradingName::string as TRADING_NAME
    , N.RECORD_CONTENT:companyDetails:businessAddress:postcode::string as BUS_ADDR_POSTCODE
    , N.RECORD_CONTENT:companyDetails:businessAddress:state::string as BUS_ADDR_STATE
    , N.RECORD_CONTENT:companyDetails:businessAddress:streetAddress::string as BUS_ADDR_STREET_ADDRESS
    , N.RECORD_CONTENT:companyDetails:businessAddress:suburb::string as BUS_ADDR_SUBURB
    , N.RECORD_CONTENT:companyDetails:registeredAddress:postcode::string as REG_ADDR_POSTCODE
    , N.RECORD_CONTENT:companyDetails:registeredAddress:state::string as REG_ADDR_STATE
    , N.RECORD_CONTENT:companyDetails:registeredAddress:streetAddress::string as REG_ADDR_STREET_ADDRESS
    , N.RECORD_CONTENT:companyDetails:registeredAddress:suburb::string as REG_ADDR_SUBURB
    , N.RECORD_CONTENT:multiSchemeId::int as MULTI_SCHEME_ID
    , N.RECORD_CONTENT:participantId::string as PARTICIPANT_ID
    , N.RECORD_CONTENT:participantNumber::string as PARTICIPANT_NUMBER  
    , TO_TIMESTAMP(N.RECORD_CONTENT:submittedAt::string) as SUBMITTED_AT
    , N.RECORD_CONTENT:registrationId::string as REGISTRATION_ID  
    , N.RECORD_CONTENT:registrationStatus::string as STATUS
    , N.RECORD_CONTENT:companyDetails:trust:trustName::string as TRUST_NAME
    , N.RECORD_CONTENT:companyDetails:trust:corporateTrustee::string as CORPORATE_TRUSTEE
    , N.RECORD_CONTENT:companyDetails:trust:businessRegistrationNumber::string as BUSINESS_REG_NUMBER  
    , N.RECORD_CONTENT:source::string as SOURCE
    , N.RECORD_CONTENT:subject::string as SUBJECT 
    , N.RECORD_CONTENT:type::string as TYPE  
    , decode(N.RECORD_CONTENT:type::string, 'au.com.ces.participant.registration.email.added.v1',1,
                                    'au.com.ces.participant.registration.abn.added.v1',2,
                                    'au.com.ces.participant.registration.company.details.added.v1',3,
                                    'au.com.ces.participant.registration.contacts.added.v1',4,
                                    'au.com.ces.participant.registration.review.pending.v1',5,
                                    'au.com.ces.participant.registration.review.information.rejected.v1',6,
                                    'au.com.ces.participant.registration.review.rejected.v1',7,
                                    'au.com.ces.participant.registration.approved.v1',8,
                                    'au.com.ces.participant.registration.participant.created.v1',9,
      99) as TYPE_ORDER    
    , N.RECORD_CONTENT:id::string as KAFKA_ID  
    , TO_TIMESTAMP(N.RECORD_CONTENT:time::string) as KAFKA_DATETIME
    FROM 
    BM as N

), BM_UNION AS ( 

  select * from (
    SELECT * FROM BM_FLATTEN 
    UNION ALL
    SELECT * FROM BM_HIST
  )
  QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1
  
  )
select * from BM_UNION
where NOT (upper(NVL(REG_EMAIL,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM', '%PVT%'))