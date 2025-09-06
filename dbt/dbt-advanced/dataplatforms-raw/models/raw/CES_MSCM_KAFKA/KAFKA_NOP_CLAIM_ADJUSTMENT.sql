{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "NOPCLAIM_ADJ_S_D" if target.name.upper() == 'DEV' else "NOPCLAIM_ADJ_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "NOPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ADJUSTMENT_ID',
        enabled = run_flag_prod()
    )
}}


WITH NOP AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} 

), NOP_FLATTEN AS (
   
SELECT 
    N.RECORD_CONTENT:data:adjustmentId::string as ADJUSTMENT_ID    
  , N.RECORD_CONTENT:data:claim:id::string as CLAIM_ID   
  , N.RECORD_CONTENT:data:adjustmentNumber::integer as ADJUSTMENT_NUMBER
  , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID  
  , N.RECORD_CONTENT:data:period::string as PERIOD
  , N.RECORD_CONTENT:data:crpSiteNumber::string as SITE_NUMBER
  , N.RECORD_CONTENT:data:status::string as STATUS
  , N.RECORD_CONTENT:data:volume::number as VOLUME  
  , N.RECORD_CONTENT:data:reason::string as REASON
  , N.RECORD_CONTENT:data:comment::string as COMMENT
  , TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate::variant) as SUBMITTED_DATE_UTC
  , N.RECORD_CONTENT:data:submittedBy::string as SUBMITTED_BY
  , N.RECORD_CONTENT:data:deviceType::string as DEVICE_TYPE
  , N.RECORD_CONTENT:data:paymentType::string as PAYMENT_TYPE
  , N.RECORD_CONTENT:data:transactionDate::date as TRANSACTION_DATE
  --, CASE WHEN N.RECORD_CONTENT:data:submittedDate::string THEN TO_TIME IS NOT NULL THEN TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate)
   -- WHEN TRY_CAST(N.RECORD_CONTENT:data:submittedDate AS TIMESTAMP_NTZ) IS NOT NULL THEN TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate) END as SUBMITTED_DATE
  , N.RECORD_CONTENT:source::string as SOURCE
  , N.RECORD_CONTENT:subject::string as SUBJECT
  , N.RECORD_CONTENT:type::string as TYPE
  , N.RECORD_CONTENT:data:refundItems::string as REFUND_ITEMS
  , N.RECORD_CONTENT:id::string as KAFKA_ID
  , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME  
FROM 
  NOP as N
WHERE TYPE = 'au.com.ces.nop.claim.adjustment.v1'
QUALIFY row_number() OVER (PARTITION BY ADJUSTMENT_ID ORDER BY KAFKA_DATETIME DESC) = 1

)
SELECT * FROM NOP_FLATTEN
WHERE (1=1) 
AND NOT (upper(NVL(SUBMITTED_BY,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))
