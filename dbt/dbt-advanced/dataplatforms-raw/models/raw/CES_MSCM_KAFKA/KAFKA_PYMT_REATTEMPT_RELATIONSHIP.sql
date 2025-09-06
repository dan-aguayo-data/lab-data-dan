{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}
{%- set src_tbl = "PAYMENTEVENT_PREVPAYREF_S" if is_incremental() else "PAYMENTEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = ['NEW_PAY_REF_NUMBER','PREV_PAY_REF_NUMBER'],
        enabled = run_flag_prod()
    )
}}


WITH source AS (
    SELECT
        *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }}
), JSON_FLATTEN AS (
    SELECT
    s.RECORD_CONTENT:id::string AS KAFKA_ID,
    s.RECORD_CONTENT:datetime::timestamp_ntz AS KAFKA_DATETIME,
    s.RECORD_CONTENT:data:newPaymentRefNumber::string AS NEW_PAY_REF_NUMBER,
    prn.value::STRING AS PREV_PAY_REF_NUMBER,
    s.RECORD_CONTENT:data:paymentId::string AS PAYMENT_ID,
    s.RECORD_CONTENT:data:refundEvent:multiSchemeId::STRING AS MULTI_SCHEME_ID,
    s.RECORD_CONTENT:modifiedBy::string AS MODIFIED_BY,
    s.RECORD_CONTENT:source::string AS SOURCE,
    s.RECORD_CONTENT:subject::string AS SUBJECT,
    s.RECORD_CONTENT:type::string AS TYPE

    FROM source s,
    LATERAL FLATTEN(INPUT => PARSE_JSON(s.RECORD_CONTENT:data:previousPaymentRefNumber), OUTER => TRUE) prn
    WHERE s.RECORD_CONTENT:type::STRING = 'au.com.coexservices.payment.reattempt.event.v1'
    QUALIFY row_number() OVER (PARTITION BY NEW_PAY_REF_NUMBER,PREV_PAY_REF_NUMBER ORDER BY KAFKA_DATETIME DESC) = 1

)
    SELECT *
    FROM JSON_FLATTEN f
    WHERE (1=1) 
    AND NOT (upper(NVL(f.MODIFIED_BY,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))        
