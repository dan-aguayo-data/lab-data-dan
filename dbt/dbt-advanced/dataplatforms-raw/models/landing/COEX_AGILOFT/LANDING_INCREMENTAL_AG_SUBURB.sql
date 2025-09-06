{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel,
        enabled = run_flag_exclude_all()
    )
}}


WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
      where lower(FILE_NAME) LIKE lower('%/AGCOLLECT%')
      QUALIFY row_number() OVER (PARTITION BY 'AGCOLLECT' ORDER BY LANDED_DATETIME DESC, FILE_NAME DESC) = 1
    )
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

SELECT 

    s.value:_1880_full_name::string as _1880_FULL_NAME,
    s.value:_1888_full_name::string as _1888_FULL_NAME,  
    s.value:abs_suburb::string as ABS_SUBURB,  
    s.value:creator_login::string as CREATOR_LOGIN,
    s.value:creator_team::string as CREATOR_TEAM,
    s.value:custom_134494115507::string as CUSTOM_134494115507, 
    s.value:custom_134494132248::string as CUSTOM_134494132248, 
    s.value:custom_134494205969::string as CUSTOM_134494205969, 
    s.value:custom_134494323738::string as CUSTOM_134494323738,      
    to_timestamp(s.value:date_created::string, 'MON DD YYYY HH:MI:SS') as DATE_CREATED,
    to_timestamp(s.value:date_updated::string, 'MON DD YYYY HH:MI:SS') as DATE_UPDATED,
    s.value:day_of_service::string as DAY_OF_SERVICE, 
    s.value:deleteable::string as DELETEABLE,  
    s.value:demo_data::string as DEMO_DATA,  
    to_date(s.value:edm_sent::string, 'MON DD YYYY') as EDM_SENT, 
    s.value:frequency::string as FREQUENCY, 
    to_date(s.value:go_live_date::string, 'MON DD YYYY') as GO_LIVE_DATE, 
    s.value:id::bigint as ID,
    s.value:legal_entity_name::string as LEGAL_ENTITY_NAME, 
    s.value:lga::string as LGA,  
    s.value:location_id::bigint as LOCATION_ID,
    s.value:population::bigint as POPULATION,  
    s.value:post_code::string as POST_CODE,  
    s.value:status::string as STATUS,
    s.value:suburb_name::string as SUBURB_NAME,
    s.value:supplier_site_name::string as SUPPLIER_SITE_NAME,
    s.value:type::string as TYPE, 
    s.value:updater_login::string as UPDATOR_LOGIN,
    s.value:updater_team::string as UPDATOR_TEAM,
    s.value
    
FROM source as s