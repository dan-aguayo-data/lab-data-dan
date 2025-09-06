{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "PAYMENTEVENT_NEWPAYREF_S" if is_incremental() else "PAYMENTEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'NEW_PAY_REF_NUMBER',
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
    s.RECORD_CONTENT:datetime::timestamp_ntz AS KAFKA_DATETIME,
    s.RECORD_CONTENT:data:approvalType::string AS APPROVAL_TYPE,
    error.value:errorId::string AS ERROR_ID,
    error.value:errorMessage::string AS ERROR_MESSAGE,
    s.RECORD_CONTENT:data:newPaymentRefNumber::string AS NEW_PAY_REF_NUMBER,
    ARRAY_TO_STRING(s.RECORD_CONTENT:data:previousPaymentRefNumber, ', ') AS PREV_PAY_REF_NUMBER,
    s.RECORD_CONTENT:data:paymentCreatedDatetime::timestamp_ntz AS PYMT_CREATED_ON,
    s.RECORD_CONTENT:data:paymentEvaluationResult::string AS PYMT_EVALUATION_RESULT,
    s.RECORD_CONTENT:data:paymentId::string AS PAYMENT_ID,
    s.RECORD_CONTENT:data:paymentMethod::string AS PYMT_METHOD,
    s.RECORD_CONTENT:data:paymentRequestId::string AS PYMT_REQUEST_ID,
    s.RECORD_CONTENT:data:recipient::string AS RECIPIENT,
    s.RECORD_CONTENT:data:refundEvent::string AS REFUND_EVENT,
    s.RECORD_CONTENT:data:status::string AS STATUS,
    s.RECORD_CONTENT:data:refundEvent:multiSchemeId::STRING AS MULTI_SCHEME_ID,
    s.RECORD_CONTENT:modifiedBy::string AS MODIFIED_BY,
    s.RECORD_CONTENT:source::string AS SOURCE,
    s.RECORD_CONTENT:subject::string AS SUBJECT,
    s.RECORD_CONTENT:type::string AS TYPE

    FROM source s,
    LATERAL FLATTEN(INPUT => PARSE_JSON(s.RECORD_CONTENT:data:errors), OUTER => TRUE) error
    WHERE s.RECORD_CONTENT:type::STRING = 'au.com.coexservices.payment.reattempt.event.v1'


)
SELECT *
FROM JSON_FLATTEN
QUALIFY row_number() OVER (PARTITION BY NEW_PAY_REF_NUMBER ORDER BY KAFKA_DATETIME DESC) = 1
