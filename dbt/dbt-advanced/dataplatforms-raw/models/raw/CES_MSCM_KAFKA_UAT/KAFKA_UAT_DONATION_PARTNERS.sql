{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "DONATION_PARTNER_UAT_S" if is_incremental() else "DONATIONPARTNEREVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'SCHEME_PARTICIPANT_ID',
        enabled = run_flag_uat()
    )
}}

WITH DONATION_PARTNER AS (

    SELECT * 
    FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}

), DONATION_PARTNER_FLATTEN AS (

        SELECT 
          N.RECORD_CONTENT:data:scheme_participant_id::string as SCHEME_PARTICIPANT_ID
        , N.RECORD_CONTENT:data:abn::string as ABN
        , DECODE(lower(N.RECORD_CONTENT:data:abn_rejected::string) , 'true', 'Y', 'false', 'N', 'N/A') as ABN_REJECTED
        , TO_DATE(nullif(N.RECORD_CONTENT:data:abn_status,'')::variant) as ABN_STATUS
        , DECODE(lower(N.RECORD_CONTENT:data:active::string) , 'true', 'Y', 'false', 'N', 'N/A') as ACTIVE
        , DECODE(lower(N.RECORD_CONTENT:data:activities_for_profit::string) , 'true', 'Y', 'false', 'N', 'N/A') as ACTIVITIES_FOR_PROFIT
        , DECODE(lower(N.RECORD_CONTENT:data:activities_in_victoria::string) , 'true', 'Y', 'false', 'N', 'N/A') as ACTIVITIES_IN_VICTORIA
        , N.RECORD_CONTENT:data:approval_status::string as APPROVAL_STATUS
        , N.RECORD_CONTENT:data:category::string as CATEGORY
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:created_at::variant) as CREATED_AT
        , N.RECORD_CONTENT:data:description::string as DESCRIPTION
        , N.RECORD_CONTENT:data:email_address::string as EMAIL_ADDRESS
        , N.RECORD_CONTENT:data:entity_name::string as ENTITY_NAME
        , N.RECORD_CONTENT:data:entity_type::string as ENTITY_TYPE
        , DECODE(lower(N.RECORD_CONTENT:data:established_for_charitable_purposes::string) , 'true', 'Y', 'false', 'N', 'N/A') as EST_FOR_CHARITABLE_PURPOSES
        , TO_DATE(nullif(N.RECORD_CONTENT:data:gst_registered,'')::variant) as GST_REGISTERED
        , DECODE(lower(N.RECORD_CONTENT:data:hidden::string) , 'true', 'Y', 'false', 'N', 'N/A') as HIDDEN
        , DECODE(lower(N.RECORD_CONTENT:data:is_organisation_school::string) , 'true', 'Y', 'false', 'N', 'N/A') as IS_ORGANISATION_SCHOOL
        , DECODE(lower(N.RECORD_CONTENT:data:legal_entity_name_match::string) , 'true', 'Y', 'false', 'N', 'N/A') as LEGAL_ENTITY_NAME_MATCH
        , N.RECORD_CONTENT:data:legal_name::string as LEGAL_NAME
        , N.RECORD_CONTENT:data:multi_scheme_id::bigint as MULTI_SCHEME_ID
        , N.RECORD_CONTENT:data:name::string as TRADING_NAME
        , N.RECORD_CONTENT:data:organisation_category::string as ORGANISATION_CATEGORY        
        , DECODE(lower(N.RECORD_CONTENT:data:stat_dec_provided::string) , 'true', 'Y', 'false', 'N', 'N/A') as STAT_DEC_PROVIDED
        , TO_TIMESTAMP(N.RECORD_CONTENT:data:updated_at::variant) as UPDATED_AT
        , N.RECORD_CONTENT:data:website_url::string as WEBSITE_URL
        , N.RECORD_CONTENT:source::string as SOURCE
        , N.RECORD_CONTENT:subject::string as SUBJECT 
        , N.RECORD_CONTENT:type::string as TYPE
        , N.RECORD_CONTENT:id::string as KAFKA_ID
        , TO_TIMESTAMP(N.RECORD_CONTENT:time::variant) as KAFKA_DATETIME
        FROM 
        DONATION_PARTNER as N
) select * from DONATION_PARTNER_FLATTEN
QUALIFY row_number() OVER (PARTITION BY SCHEME_PARTICIPANT_ID ORDER BY KAFKA_DATETIME DESC) = 1