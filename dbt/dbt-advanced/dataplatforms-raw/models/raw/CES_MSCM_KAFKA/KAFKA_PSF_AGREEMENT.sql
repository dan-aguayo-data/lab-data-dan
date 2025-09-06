{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "PSF_AGREEMENT_S_D" if target.name.upper() == 'DEV' else "PSF_AGREEMENT_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "POSAGREEMENTEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'AGREEMENT_ID',
        enabled = run_flag_prod()
    )
}}


WITH PSF_AGREEMENT AS (

    SELECT * 
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} 

), PSF_AGREEMENT_FLATTEN AS (

        SELECT 
          N.RECORD_CONTENT:data:agreementId::string as AGREEMENT_ID
        , N.RECORD_CONTENT:data:agreementNumber::string as AGREEMENT_NUMBER
        , N.RECORD_CONTENT:data:version::bigint as VERSION
        , N.RECORD_CONTENT:data:status::string as STATUS
        , N.RECORD_CONTENT:data:feeRate::float as FEE_RATE
        , N.RECORD_CONTENT:data:feeType::string as FEE_TYPE
        , N.RECORD_CONTENT:data:multiSchemeId::bigint as MULTI_SCHEME_ID
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:effectiveDate:from::variant) as EFFECTIVE_DATE_FROM
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:effectiveDate:to::variant) as EFFECTIVE_DATE_TO
        , N.RECORD_CONTENT:data:effectiveDate:timezone::string as EFFECTIVE_DATE_TIMEZONE
        , N.RECORD_CONTENT:data:customer:customerNumber::string as CUSTOMER_NUMBER
        , N.RECORD_CONTENT:data:customer:customerSiteNumber::string as CUSTOMER_SITE_NUMBER
        , N.RECORD_CONTENT:data:customer:id::string as CUSTOMER_ID
        , N.RECORD_CONTENT:data:participant:participantNumber::string as PARTICIPANT_NUMBER
        , N.RECORD_CONTENT:data:participant:participantSiteName::string as PARTICIPANT_SITE_NAME
        , N.RECORD_CONTENT:data:participant:participantSiteNumber::string as PARTICIPANT_SITE_NUMBER
        , N.RECORD_CONTENT:data:participant:type::string as PARTICIPANT_TYPE
        , N.RECORD_CONTENT:modifiedBy::string as MODIFIEDBY  
        , MIN(TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant)) OVER (PARTITION BY N.RECORD_CONTENT:data:agreementId::string ORDER BY 1) as CREATED_ON
        , N.RECORD_CONTENT:source::string as SOURCE
        , N.RECORD_CONTENT:subject::string as SUBJECT 
        , N.RECORD_CONTENT:type::string as TYPE
        , N.RECORD_CONTENT:id::string as KAFKA_ID
        , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
        FROM 
        PSF_AGREEMENT as N
        QUALIFY row_number() OVER (PARTITION BY AGREEMENT_ID ORDER BY KAFKA_DATETIME DESC) = 1 
)
SELECT * FROM PSF_AGREEMENT_FLATTEN
WHERE (1=1) 
AND NOT (upper(NVL(MODIFIEDBY,'NULL')) LIKE ANY ('%@YOPMAIL.COM', '%COEXSERVICES.INFO', '%TESTINATOR.COM'))