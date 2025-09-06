{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "NOPCLAIM_REFUND_S_D" if target.name.upper() == 'DEV' else "NOPCLAIM_REFUND_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "NOPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'REFUND_TRANSACTION_ID',
        enabled = run_flag_prod()
    )
}}


WITH NOP AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }}
    WHERE RECORD_CONTENT:type::string ='au.com.ces.nop.claim.refund.v1'

), NOP_FLATTEN AS (

    SELECT 
      N.RECORD_CONTENT:data:refundTransactionId::string as REFUND_TRANSACTION_ID
    , N.RECORD_CONTENT:data:externalRefundId::string as EXTERNAL_REFUND_ID
    , N.RECORD_CONTENT:source::string as SOURCE
    , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant) as DATETIME
    , N.RECORD_CONTENT:subject::string as SUBJECT
    , N.RECORD_CONTENT:type::string as TYPE
    , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID
    , N.RECORD_CONTENT:data:period::string as PERIOD
    , TO_DATE(N.RECORD_CONTENT:data:transactionDate::variant) as TRANSACTION_DATE
    , TO_TIMESTAMP(N.RECORD_CONTENT:data:transactedOnUTC::variant) as TRANSACTED_ON_UTC
    , N.RECORD_CONTENT:data:claim:id::string as CLAIM_ID
    , N.RECORD_CONTENT:data:claim:status::string as STATUS
    , N.RECORD_CONTENT:data:paymentType::string as PAYMENT_TYPE
    , N.RECORD_CONTENT:data:crpSiteNumber::string as CRP_SITE_NUMBER
    , N.RECORD_CONTENT:data:lateSync::string as LATE_SYNC
    , N.RECORD_CONTENT:data:refundItems::string as REFUND_ITEMS
    , N.RECORD_CONTENT:id::string as KAFKA_ID    
    , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
    FROM 
    NOP as N
)
SELECT * FROM NOP_FLATTEN
QUALIFY row_number() OVER (PARTITION BY REFUND_TRANSACTION_ID ORDER BY KAFKA_DATETIME DESC) = 1