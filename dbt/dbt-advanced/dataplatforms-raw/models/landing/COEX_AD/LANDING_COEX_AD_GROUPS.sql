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
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_AD') }}
      where upper(FILE_NAME) like '%/GROUPS/%'
      QUALIFY row_number() OVER (PARTITION BY 'COEX_AD' ORDER BY LANDED_DATETIME DESC) = 1
    )


)

select 
s.value:id::string as ID,
s.value:createdDateTime::timestamp_ntz as CREATEDDATETIME,
s.value:description::string as DESCRIPTION,
s.value:displayName::string as DISPLAYNAME,
ARRAY_TO_STRING(PARSE_JSON(s.value:groupTypes::string), ', ') as GROUPTYPES, -- elements in the array if more than 2 will be split by a comma and space, and null parameter is not used
s.value:mail::string as MAIL,
s.value:mailEnabled::string as MAILENABLED,
s.value:mailNickname::string as MAILNICKNAME,
s.value:renewedDateTime::timestamp_ntz as RENEWEDDATETIME,
s.value:securityEnabled::string as SECURITYENABLED,
s.value:visibility::string as VISIBILITY,
s.value 

from source as s