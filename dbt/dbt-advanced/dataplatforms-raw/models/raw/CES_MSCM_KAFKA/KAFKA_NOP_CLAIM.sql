{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "NOPCLAIM_S_D" if target.name.upper() == 'DEV' else "NOPCLAIM_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "NOPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_prod()
    )
}}

 
WITH NOP AS (

    SELECT * 
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} 

), NOP_FLATTEN AS (

        SELECT 
          N.RECORD_CONTENT:data:id::string||'-'||N.RECORD_CONTENT:data:status::string  as ID
        , N.RECORD_CONTENT:data:id::string as CLAIM_ID
        , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID
        , N.RECORD_CONTENT:data:period::string as PERIOD
        , N.RECORD_CONTENT:data:status::string as STATUS
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:submittedDate::variant) as SUBMITTED_DATE_UTC
        , N.RECORD_CONTENT:data:submittedBy::string as SUBMITTED_BY
        , N.RECORD_CONTENT:data:estimatedPaymentDate::date as ESTIMATED_PAYMENT_DATE
        , N.RECORD_CONTENT:data:volume::string as VOLUME
        , N.RECORD_CONTENT:type::string as TYPE
        , N.RECORD_CONTENT:source::string as SOURCE
        , N.RECORD_CONTENT:subject::string as SUBJECT 
        , N.RECORD_CONTENT:id::string as KAFKA_ID
        , (CASE RLIKE(lower(N.RECORD_CONTENT:datetime), '.*[a-z].*') WHEN TRUE THEN to_timestamp(N.RECORD_CONTENT:datetime::string) ELSE to_timestamp(parse_json(N.RECORD_CONTENT:datetime::string)) END) as KAFKA_DATETIME
        FROM 
        NOP as N
        WHERE TYPE NOT IN ('au.com.ces.nop.claim.adjustment.v1', 'au.com.ces.nop.claim.refund.v1')
        QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1 
)
SELECT * FROM NOP_FLATTEN
WHERE (1=1) 
AND NOT (upper(NVL(SUBMITTED_BY,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))
