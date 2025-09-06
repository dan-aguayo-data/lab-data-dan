{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PAYMENT_UAT_S" if is_incremental() else "PAYMENTEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'KAFKA_ID',
        enabled = run_flag_uat()
    )
}}


WITH source AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}

), PYMT_FLATTEN AS (

    SELECT
     s.RECORD_CONTENT:id::string as KAFKA_ID 
    ,s.RECORD_CONTENT:data:refundEvent:multiSchemeId::number as MULTI_SCHEME_ID
    ,s.RECORD_CONTENT:data:paymentEvaluationResult:runId::string as RUN_ID
    ,s.RECORD_CONTENT:data:paymentId::string as PAYMENT_ID
    ,s.RECORD_CONTENT:source::string as SOURCE
    ,s.RECORD_CONTENT:subject::string as SUBJECT
    ,s.RECORD_CONTENT:datetime::TIMESTAMP_NTZ as KAFKA_DATETIME
    ,s.RECORD_CONTENT:type::string as TYPE
    ,s.RECORD_CONTENT:modifiedBy::string as MODIFIED_BY
    ,s.RECORD_CONTENT:data:paymentMethod::string as PAYMENT_METHOD
    ,NVL(s.RECORD_CONTENT:data:paymentRefNumber::number, s.RECORD_CONTENT:data:newPaymentRefNumber::number) as PAY_REF_NUMBER
    ,ARRAY_TO_STRING(s.RECORD_CONTENT:data:previousPaymentRefNumber, ', ') AS PREV_PAY_REF_NUMBER
    ,s.RECORD_CONTENT:data:paymentRequestId::string as PAYMENT_REQUEST_ID
    ,s.RECORD_CONTENT:data:status::string as STATUS
    ,s.RECORD_CONTENT:data:amountToPay:total::decimal(18,2) as TOTAL_AMOUNT_TO_PAY
    ,s.RECORD_CONTENT:data:amountToPay:currency::string as CURRENCY
    ,s.RECORD_CONTENT:data:paymentEvaluationResult:ruleEngineVersion::string as RULE_ENGINE_VERSION
    ,s.RECORD_CONTENT:data:paymentEvaluationResult:passed::boolean as PASSED
    ,s.RECORD_CONTENT:data:refundEvent:refundTransactionId::string as TRANSACTION_ID
    ,s.RECORD_CONTENT:data:refundEvent:transactionType::string as TRANSACTION_TYPE
    ,s.RECORD_CONTENT:data:refundEvent:transactionDate::string as TRANSACTION_DATE
    ,s.RECORD_CONTENT:data:refundEvent:transactionTimezone::string as TRANSACTION_TIMEZONE
    ,s.RECORD_CONTENT:data:refundEvent:customerDeclaration::boolean as CUSTOMER_DECLARATION
    ,s.RECORD_CONTENT:data:refundEvent:customerId::string as CUSTOMER_ID
    ,s.RECORD_CONTENT:data:refundEvent:customerNumber::string as CONSUMER_ID
    ,s.RECORD_CONTENT:data:refundEvent:deviceId::string as DEVICE_ID
    ,s.RECORD_CONTENT:data:refundEvent:crpSiteNumber::string as CRP_SITE_NUMBER
    ,s.RECORD_CONTENT:data:refundEvent:totalAmount::float as GROSS_AMOUNT
    ,s.RECORD_CONTENT:data:refundEvent:taxableAmount::float as TAXABLE_AMOUNT
    ,s.RECORD_CONTENT:data:refundEvent:getAmount::float as GST_AMOUNT
    ,s.RECORD_CONTENT:data:recipient:participantId::string as RECIPIENT_CUSTOMER_ID
    ,s.RECORD_CONTENT:data:recipient:participantNumber::string as RECIPIENT_PARTICIPANT_NUMBER
    ,s.RECORD_CONTENT:data:recipient:participantSiteId::string as RECIPIENT_SITE_NUMBER
    ,s.RECORD_CONTENT:data:recipient:type::string as RECIPIENT_TYPE
    ,s.RECORD_CONTENT:data:recipient:name::string as RECIPIENT_NAME
    ,s.RECORD_CONTENT:data:recipient:paymentProfileId::string as PAYMENT_PROFILE_ID
    ,s.RECORD_CONTENT:data:recipient:delegateProfile::string as DELEGATE_PROFILE
    ,s.RECORD_CONTENT:data:latestPayrun:payrunId::string as PAYRUN_ID
    ,s.RECORD_CONTENT:data:latestPayrun:todayOrder::number as TODAY_ORDER
    ,s.RECORD_CONTENT:data:latestPayrun:paymentsCreatedOnAndBefore::string as PAYMENTS_CREATED_ON_AND_BEFORE
    ,s.RECORD_CONTENT:data:latestPayrun:payrunStatus::string as PAYRUN_STATUS
    ,s.RECORD_CONTENT:data:refundEvent:posServiceFee:agreementId:string as AGREEMENT_ID
    ,s.RECORD_CONTENT:data:refundEvent:posServiceFee:serviceFeeAmount::number as POS_SERVICE_FEE_AMOUNT
    ,s.RECORD_CONTENT:data:refundEvent:recipientId::string as RECIPIENT_ID
    ,s.RECORD_CONTENT:data:refundEvent:recipientNumber::string as RECIPIENT_NUMBER
    ,s.RECORD_CONTENT:data:refundEvent:serviceFeeAmount::float as SERVICE_FEE_AMOUNT
    FROM
    source as s
)
SELECT * FROM PYMT_FLATTEN
QUALIFY row_number() OVER (PARTITION BY KAFKA_ID ORDER BY KAFKA_DATETIME DESC) = 1