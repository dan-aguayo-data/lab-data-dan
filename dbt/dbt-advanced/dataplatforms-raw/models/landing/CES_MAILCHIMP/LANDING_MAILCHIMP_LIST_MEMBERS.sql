{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (

  SELECT *
  FROM
  {{ source('SNOWPIPE_PROD', 'CES_MAILCHIMP_PROD') }}
  WHERE
  FILE_NAME=(
    select FILE_NAME from {{ source('SNOWPIPE_PROD', 'CES_MAILCHIMP_PROD') }}
    where lower(FILE_NAME) like lower('coex/LIST_MEMBERS/%')
    QUALIFY row_number() OVER (PARTITION BY 'LIST_MEMBERS' ORDER BY LANDED_DATETIME DESC) = 1
  )
),
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:members) f
    
)
  SELECT
    s.value:consents_to_one_to_one_messaging::string as CONSENTS_TO_ONE_TO_ONE_MESSAGING,
    s.value:contact_id::string as CONTACT_ID,
    s.value:email_address::string as EMAIL_ADDRESS,
    s.value:email_client::string as EMAIL_CLIENT,
    s.value:email_type::string as EMAIL_TYPE,
    s.value:full_name::string as FULL_NAME,
    s.value:id::string as ID,
    s.value:ip_opt::string as IP_OPT,
    s.value:ip_signup::string as IP_SIGNUP,
    s.value:language::string as LANGUAGE,
    nullif(s.value:last_changed,'')::TIMESTAMP_NTZ as LAST_CHANGED,
    s.value:list_id::string as LIST_ID,
    s.value:location:country_code::string as COUNTRY_CODE,
    s.value:location:dstoff::bigint as DSTOFF,
    s.value:location:gmtoff::bigint as GMTOFF,
    s.value:location:latitude::float as LATITUDE,
    s.value:location:longitude::float as LONGITUDE,
    s.value:location:region::string as LOCATION_REGION,
    s.value:location:timezone::string as TIMEZONE,   
    s.value:member_rating::bigint as MEMBER_RATING,   
    s.value:merge_fields:ACTIVE_ID::string as ACTIVE_ID,
    s.value:merge_fields:AGED_CARE::string as AGED_CARE,
    s.value:merge_fields:ANIMALS::string as ANIMALS,
    s.value:merge_fields:ARTS_CULT::string as ARTS_CULT,
    s.value:merge_fields:COMM_DEV::string as COMM_DEV,
    s.value:merge_fields:COMP_PROMO::string as COMP_PROMO,
    s.value:merge_fields:COM_SAFETY::string as COM_SAFETY,
    s.value:merge_fields:CONT_RET::string as CONT_RET,
    s.value:merge_fields:DISABILITY::string as DISABILITY,
    s.value:merge_fields:DIS_RELIEF::string as DIS_RELIEF,
    s.value:merge_fields:EDUCATION::string as EDUCATION,
    s.value:merge_fields:ENTRIES::string as ENTRIES,
    s.value:merge_fields:ENVIRON::string as ENVIRON,
    s.value:merge_fields:EVENTS::string as EVENTS,
    s.value:merge_fields:FAM_VIOLEN::string as FAM_VIOLEN,
    s.value:merge_fields:FNAME::string as FNAME,
    s.value:merge_fields:LNAME::string as LNAME,    
    s.value:merge_fields:HEALTH::string as HEALTH,
    s.value:merge_fields:HUMAN_CIVL::string as HUMAN_CIVL,
    s.value:merge_fields:HUMAN_SERV::string as HUMAN_SERV,
    s.value:merge_fields:INDEG_AU::string as INDEG_AU,
    s.value:merge_fields:INTERNAT::string as INTERNAT,
    s.value:merge_fields:MHS::string as MHS,
    s.value:merge_fields:MMERGE37::string as MMERGE37,
    s.value:merge_fields:MMERGE40::string as MMERGE40,
    s.value:merge_fields:NEWS::string as NEWS,
    s.value:merge_fields:NEXT_ENT::string as NEXT_ENT,
    s.value:merge_fields:POST_CODE::string as POST_CODE,
    s.value:merge_fields:REGION::string as REGION,
    nullif(s.value:merge_fields:REG_DATE,'')::date as REG_DATE,
    s.value:merge_fields:RELIGION::string as RELIGION,
    s.value:merge_fields:RESEARCH::string as RESEARCH,
    s.value:merge_fields:RPUPDATE::string as RPUPDATE,
    s.value:merge_fields:SCHEME_ID::string as SCHEME_ID,
    s.value:merge_fields:SOCIAL_ENT::string as SOCIAL_ENT,
    s.value:merge_fields:STAFF::string as STAFF,
    s.value:merge_fields:TAXONOMY::string as TAXONOMY,
    s.value:merge_fields:TESTENT::string as TESTENT,
    s.value:merge_fields:TRAD_NAME::string as TRAD_NAME,
    s.value:merge_fields:VET_SERV::string as VET_SERV,
    s.value:merge_fields:WEB_CONS::string as WEB_CONS,
    s.value:merge_fields:WEB_DESC::string as WEB_DESC,
    s.value:merge_fields:YSS::string as YSS,
    s.value:source::string as SOURCE,
    s.value:stats:avg_click_rate::float as AVG_CLICK_RATE,
    s.value:stats:avg_open_rate::float as AVG_OPEN_RATE,
    s.value:status::string as STATUS,
    nullif(s.value:timestamp_opt,'')::TIMESTAMP_NTZ as TIMESTAMP_OPT,
    nullif(s.value:timestamp_signup,'')::TIMESTAMP_NTZ as TIMESTAMP_SIGNUP,
    s.value:unique_email_id::string as UNIQUE_EMAIL_ID,
    s.value:vip::string as VIP,
    s.value:web_id::string as WEB_ID
FROM source as s