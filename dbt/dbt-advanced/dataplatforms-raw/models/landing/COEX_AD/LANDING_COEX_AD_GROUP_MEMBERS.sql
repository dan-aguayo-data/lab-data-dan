{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}


{{  
    config(
        alias=trimmed_source_rel
    )
}}


WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, f.VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_AD') }} s,
    lateral flatten(input => s.MESSAGE:value) f
    where 
    FILE_NAME=(
      select FILE_NAME  from {{ source('SNOWPIPE_PROD', 'COEX_AD') }}
      where upper(FILE_NAME) like '%/GROUPMEMBERS/%'
      QUALIFY row_number() OVER (PARTITION BY 'COEX_AD' ORDER BY LANDED_DATETIME DESC) = 1
    )


)

select
s.value:id::string||'-'||f.value:id::string as ID,  --added so we could have table primary key (normalized data)
s.value:id::string as GROUPID,
s.value:displayName::string as GROUPNAME,
f.value:id::string as MEMBERID,   
f.value:displayName::string as MEMBERNAME,
f.value 
from source as s,
lateral flatten(input => s.value:members) f