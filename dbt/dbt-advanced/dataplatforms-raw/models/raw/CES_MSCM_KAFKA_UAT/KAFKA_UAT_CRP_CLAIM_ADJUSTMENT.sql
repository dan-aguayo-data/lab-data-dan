{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "CRPCLAIM_ADJ_UAT_S" if is_incremental() else "CRPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ADJUSTMENT_ID',
        enabled = run_flag_uat()
    )
}}

WITH CRP AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }} 

), CRP_FLATTEN AS (

SELECT 
      N.RECORD_CONTENT:data:adjustmentId::string as ADJUSTMENT_ID
    , N.RECORD_CONTENT:data:claim:id::string as CLAIM_ID
    , N.RECORD_CONTENT:data:adjustmentNumber::string as ADJUSTMENT_NUMBER
    , N.RECORD_CONTENT:data:adjustmentReason::string as ADJUSTMENT_REASON
    , N.RECORD_CONTENT:data:adjustmentComment::string as ADJUSTMENT_COMMENT
    , N.RECORD_CONTENT:data:crpSiteNumber::string as SITE_NUMBER
    , N.RECORD_CONTENT:data:deviceType::string as DEVICE_TYPE
    , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID
    , N.RECORD_CONTENT:data:period::string as PERIOD
    , N.RECORD_CONTENT:data:periodType::string as PERIOD_TYPE
    , N.RECORD_CONTENT:data:ssAuditAdjustmentId::string as AUDIT_ADJUSTMENT_ID    
    , N.RECORD_CONTENT:data:status::string as STATUS
    , N.RECORD_CONTENT:data:submittedBy::string as SUBMITTED_BY
    , TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate::variant) as SUBMITTED_DATE
    , to_date(N.RECORD_CONTENT:data:transactionDate::string,'dd-mm-yyyy') as TRANSACTION_DATE
    --, N.RECORD_CONTENT:data:volume::string as VOLUME
    , N.RECORD_CONTENT:modifiedBy::string as MODIFIED_BY
    , N.RECORD_CONTENT:source::string as SOURCE
    , N.RECORD_CONTENT:subject::string as SUBJECT 
    , N.RECORD_CONTENT:type::string as TYPE  
    , N.RECORD_CONTENT:id::string as KAFKA_ID  
    , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::string) as KAFKA_DATETIME
    FROM 
    CRP as N
    WHERE TYPE IN ('au.com.ces.crp.claim.adjustment.v1')
)    
SELECT * FROM CRP_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ADJUSTMENT_ID ORDER BY KAFKA_DATETIME DESC) = 1