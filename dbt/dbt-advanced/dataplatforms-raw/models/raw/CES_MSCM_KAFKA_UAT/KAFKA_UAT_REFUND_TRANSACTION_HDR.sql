{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "REFUND_TRANSACTION_HDR_UAT_S" if is_incremental() else "POSREFUNDSERVICEREFUNDTRANSACTIONTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'REFUND_TRANSACTION_ID',
        enabled = run_flag_uat()
    )
}}

WITH source AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}

), REFUND_FLATTEN AS (

    SELECT
     s.RECORD_CONTENT:data:refundTransactionId::string as REFUND_TRANSACTION_ID
    ,s.RECORD_CONTENT:type::string as TYPE
    ,s.RECORD_CONTENT:source::string as SOURCE
    ,s.RECORD_CONTENT:subject::string as SUBJECT
    ,s.RECORD_CONTENT:modifiedBy::string as MODIFIEDBY
    ,s.RECORD_CONTENT:data:agreement::string as AGREEMENT
    ,s.RECORD_CONTENT:data:agreement:agreementNumber::string as AGREEMENT_NUMBER
    ,s.RECORD_CONTENT:data:agreement:fee:rate::float as AGREEMENT_FEE_RATE
    ,s.RECORD_CONTENT:data:agreement:fee:type::string as AGREEMENT_FEE_TYPE       
    ,s.RECORD_CONTENT:data:bagDrop::string as BAG_DROP
    ,s.RECORD_CONTENT:data:crpSiteNumber::string as CRP_SITE_NUMBER
    ,s.RECORD_CONTENT:data:customerDeclaration::string as CUSTOMER_DECLARATION
    ,s.RECORD_CONTENT:data:customerId::string as CUSTOMER_ID 
    ,s.RECORD_CONTENT:data:customerNumber::string as CUSTOMER_NUMBER 
    ,s.RECORD_CONTENT:data:deviceId::string as DEVICE_ID 
    ,s.RECORD_CONTENT:data:deviceName::string as DEVICE_NAME 
    ,s.RECORD_CONTENT:data:deviceType::string as DEVICE_TYPE 
    ,s.RECORD_CONTENT:data:gstAmount::float as GST_AMOUNT
    ,s.RECORD_CONTENT:data:multiSchemeId::number as MULTI_SCHEME_ID 
    ,s.RECORD_CONTENT:data:paymentType::string as PAYMENT_TYPE 
    ,s.RECORD_CONTENT:data:recipientId::string as RECIPIENT_ID
    ,NVL(s.RECORD_CONTENT:data:recipientNumber::string,s.RECORD_CONTENT:data:recipientSchemeId::string) as RECIPIENT_NUMBER
    ,s.RECORD_CONTENT:data:externalMemberId::string as EXTERNAL_MEMBER_ID 
    ,s.RECORD_CONTENT:data:externalRefundId::string as EXTERNAL_REFUND_ID    
    ,s.RECORD_CONTENT:data:serviceFeeAgreement::string as SERVICE_FEE_AGREEMENT
    ,s.RECORD_CONTENT:data:serviceFeeAgreement:override:rate::float as SERVICE_FEE_AGREEMENT_OVERRIDE_RATE
    ,s.RECORD_CONTENT:data:serviceFeeAgreement:override:total::float as SERVICE_FEE_AGREEMENT_OVERRIDE_TOTAL
    ,s.RECORD_CONTENT:data:serviceFeeAgreement:type::string as SERVICE_FEE_AGREEMENT_TYPE     
    ,s.RECORD_CONTENT:data:serviceFeeAmount::float as SERVICE_FEE_AMOUNT
    ,s.RECORD_CONTENT:data:taxableAmount::float as TAXABLE_AMOUNT
    ,s.RECORD_CONTENT:data:totalAmount::float as TOTAL_AMOUNT
    ,s.RECORD_CONTENT:data:totalContainerCount::number as TOTAL_CONTAINER_COUNT
    ,s.RECORD_CONTENT:data:transactedBy::string as TRANSACTED_BY
    ,s.RECORD_CONTENT:data:transactionSubmittedBy::string as TRANSACTION_SUBMITTED_BY
    ,TO_TIMESTAMP((CASE WHEN SUBSTR(s.RECORD_CONTENT:data:transactionDate, -3, 1)= '+' THEN s.RECORD_CONTENT:data:transactionDate||':00'::string ELSE s.RECORD_CONTENT:data:transactionDate END)) TRANSACTION_DATE
    ,s.RECORD_CONTENT:data:transactionTimezone::string as TRANSACTION_TIMEZONE
    ,s.RECORD_CONTENT:data:transactionType::string as TRANSACTION_TYPE
    ,s.RECORD_CONTENT:id::string as KAFKA_ID
    ,TO_TIMESTAMP(s.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
    FROM
    source as s
    
), REFUND_FLATTEN_UNION as (

    SELECT * FROM REFUND_FLATTEN where TYPE not in ('au.com.ces.refund.noncontracted.customer.v1','au.com.ces.refund.noncontracted.crp.v1')
    QUALIFY row_number() OVER (PARTITION BY REFUND_TRANSACTION_ID ORDER BY KAFKA_DATETIME DESC) = 1
    UNION ALL
    SELECT * FROM REFUND_FLATTEN where TYPE in ('au.com.ces.refund.noncontracted.customer.v1','au.com.ces.refund.noncontracted.crp.v1')
    {% if is_incremental() %}
    and
       EXTERNAL_REFUND_ID not in (select EXTERNAL_REFUND_ID from {{this}} where EXTERNAL_REFUND_ID is not null)
    {% endif %}     
    QUALIFY row_number() OVER (PARTITION BY EXTERNAL_REFUND_ID ORDER BY KAFKA_DATETIME) = 1    
  
)
SELECT * FROM REFUND_FLATTEN_UNION