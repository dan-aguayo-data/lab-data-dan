{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PARTICREG_UAT_S" if is_incremental() else "PARTICIPANTREGISTRATIONEVENTTOPIC" -%}

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

)
select * from BM_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1 