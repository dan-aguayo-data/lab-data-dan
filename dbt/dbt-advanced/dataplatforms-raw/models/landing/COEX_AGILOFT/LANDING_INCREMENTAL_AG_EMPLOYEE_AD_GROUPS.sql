{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
      where lower(FILE_NAME) LIKE lower('%/AGEmployeeADGroups%')
      QUALIFY row_number() OVER (PARTITION BY 'AGEmployeeADGroups' ORDER BY LANDED_DATETIME DESC, FILE_NAME DESC) = 1
    )

)
select 
  array_to_string(parse_json(s.value:ad_groups_ces), ', ') as AD_GROUPS_CES,
  array_to_string(parse_json(s.value:ad_groups_coex), ', ') as AD_GROUPS_COEX,
  to_timestamp(s.value:date_created::string, 'MMMM DD YYYY hh24:mi:ss') as DATE_CREATED,
  to_timestamp(s.value:date_updated::string, 'MMMM DD YYYY hh24:mi:ss') as DATE_UPDATED,
  s.value:email1::string as EMAIL1,
  s.value:email2::string as EMAIL2,
  s.value:employee_id::string as EMPLOYEE_ID,
  s.value:first_name::string as FIRST_NAME,
  s.value:last_name::string as LAST_NAME,
  s.value:mobile::bigint as MOBILE,
  s.value:employee_status::string as EMPLOYEE_STATUS
  
from source as s