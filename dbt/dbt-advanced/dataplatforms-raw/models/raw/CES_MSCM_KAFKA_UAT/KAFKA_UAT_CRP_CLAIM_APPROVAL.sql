{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "CRPCLAIM_APPROVAL_UAT_S" if is_incremental() else "CRPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_uat()
    )
}}

WITH CRP AS (

    SELECT * 
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }} 
    WHERE RECORD_CONTENT:type::string IN ('au.com.ces.crp.claim.submission.approval.v1', 'au.com.ces.crp.claim.adjustment.approval.v1')
  
), CRP_FLATTEN AS (

        SELECT 
          N.RECORD_CONTENT:data:id::string||'-'||N.RECORD_CONTENT:data:status::string  as ID
        , N.RECORD_CONTENT:id::string as KAFKA_ID
        , N.RECORD_CONTENT:data:id::string as CLAIM_ID
        , N.RECORD_CONTENT:data:crpSiteNumber::string as CRP_SITE_NUMBER
        , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID
        , N.RECORD_CONTENT:data:period::string as PERIOD
        , N.RECORD_CONTENT:data:periodType::string as PERIOD_TYPE
        , N.RECORD_CONTENT:data:reviewedBy::string as REVIEWED_BY
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:reviewedDate::variant) as REVIEWED_DATE_UTC
        , N.RECORD_CONTENT:data:status::string as STATUS
        , N.RECORD_CONTENT:data:submittedBy::string as SUBMITTED_BY
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate::variant) as SUBMITTED_DATE_UTC
        , N.RECORD_CONTENT:data:volume::float as VOLUME
        , N.RECORD_CONTENT:type::string as TYPE
        , N.RECORD_CONTENT:source::string as SOURCE
        , N.RECORD_CONTENT:subject::string as SUBJECT 
        , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
        , N.RECORD_CONTENT:data:adjustmentNumber::string as ADJUSTMENT_NUMBER
        , N.RECORD_CONTENT:data:comment::string as ADJ_COMMENT
        , N.RECORD_CONTENT:data:reason::string as ADJ_REASON
        , N.RECORD_CONTENT:data:ssAuditAdjustmentId::string as SS_AUDIT_ADJUSTMENT_ID
        , (CASE N.RECORD_CONTENT:type::string WHEN 'au.com.ces.crp.claim.submission.approval.v1' THEN 'R' ELSE 'A' END) TYPE_FLAG
        FROM 
        CRP as N
)
SELECT * FROM CRP_FLATTEN 
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1
