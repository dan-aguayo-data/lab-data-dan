{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "CRPCLAIM_S_D" if target.name.upper() == 'DEV' else "CRPCLAIM_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "CRPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_prod() 
        
    )
}}

WITH CRP AS (

    SELECT * 
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} 

), CRP_FLATTEN AS (
  
    SELECT 
      N.RECORD_CONTENT:data:id::string||'-'||N.RECORD_CONTENT:data:status::string  as ID
    , N.RECORD_CONTENT:data:id::string as CLAIM_ID
    , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID
    , N.RECORD_CONTENT:data:period::string as PERIOD
    , N.RECORD_CONTENT:data:crpSiteNumber::string as SITE_NUMBER
    , N.RECORD_CONTENT:data:periodType::string as PERIOD_TYPE
    , N.RECORD_CONTENT:data:status::string as STATUS
    , TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate::variant) as SUBMITTED_DATE        
    , N.RECORD_CONTENT:data:submittedBy::string as SUBMITTED_BY
    , N.RECORD_CONTENT:data:volume::string as VOLUME
    , N.RECORD_CONTENT:modifiedBy::string as MODIFIED_BY
    , N.RECORD_CONTENT:source::string as SOURCE
    , N.RECORD_CONTENT:subject::string as SUBJECT 
    , N.RECORD_CONTENT:type::string as TYPE    
    , N.RECORD_CONTENT:id::string as KAFKA_ID
    , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::string) as KAFKA_DATETIME
    FROM 
    CRP as N
    WHERE TYPE IN ('au.com.ces.crp.claim.submission.v1', 'au.com.ces.crp.claim.submission.v2')
    QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1
)
SELECT * FROM CRP_FLATTEN
WHERE (1=1) 
AND NOT (upper(NVL(MODIFIED_BY,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))