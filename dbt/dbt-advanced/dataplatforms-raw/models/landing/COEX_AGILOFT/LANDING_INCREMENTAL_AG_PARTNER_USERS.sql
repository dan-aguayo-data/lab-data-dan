{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
      where lower(FILE_NAME) LIKE lower('%/AGPARTNERSUSERS%')
      QUALIFY row_number() OVER (PARTITION BY 'AGPARTNERSUSERS' ORDER BY LANDED_DATETIME DESC, FILE_NAME DESC) = 1
    )

) 

SELECT 
    s.value:id::bigint as ID,
    s.value:first_name::string as FIRST_NAME,
    s.value:last_name::string as LAST_NAME,
    s.value:launch_date::string as LAUNCH_DATE,
    s.value:partner_parent::string as PARTNER_PARENT,
    s.value:partner_site::string as PARTNER_SITE,    
    s.value:type::string as TYPE,
    s.value:status::string as STATUS,
    s.value:school_name::string as SCHOOL_NAME,
    s.value:sub_category::string as SUB_CATEGORY,
    s.value:category::string as CATEGORY,
    s.value:email::string as EMAIL,
    s.value:scheme_id::string as SCHEME_ID,
    s.value:partner_id::string as PARTNER_ID,
    to_timestamp(s.value:date_created::string, 'MON DD YYYY HH:MI:SS') as DATE_CREATED,
    to_timestamp(s.value:date_updated::string, 'MON DD YYYY HH:MI:SS') as DATE_UPDATED,
    s.value
    
FROM source as s