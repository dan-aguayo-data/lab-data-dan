{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}


{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, f.value
    FROM  {{ source('SNOWPIPE_PROD', 'COEX_AD') }} s, lateral flatten(input => s.MESSAGE:value) f
   where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_AD') }}
      where upper(FILE_NAME) like '%/USERS/%'
      QUALIFY row_number() OVER (PARTITION BY 'COEX_AD' ORDER BY LANDED_DATETIME DESC) = 1
    )
)
select 
s.value:id::string as ID,
s.value:accountEnabled::boolean as ACOUNTENABLED,
ARRAY_TO_STRING(PARSE_JSON(s.value:businessPhones::string), ', ') as BUSINESSPHONES,  --not asked for but converted into string as there was an array format
s.value:city::string as CITY,
s.value:createdDateTime::timestamp_ntz as CREATEDDATETIME,
s.value:companyName::string as COMPANYNAME,
s.value:country::string as COUNTRY,
s.value:department::string as DEPARTMENT,
s.value:displayName::string as DISPLAYNAME,
s.value:employeeid::string as EMPLOYEEID,
s.value:employeeHireDate::timestamp_ntz as EMPLOYEEHIREDATE,
s.value:employeeLeaveDateTime::timestamp_ntz as EMPLOYEELEAVEDATETIME,
s.value:employeeType::string as EMPLOYEETYPE,
s.value:givenName::string as GIVENNAME,
s.value:jobTitle::string as JOBTITLE,
s.value:mail::string as MAIL,
s.value:mailNickname::string as MAILNICKNAME,
s.value:mobilePhone::string as MOBILEPHONE,
s.value:passwordPolicies::string as PASSWORDPOLICIES,
s.value:postalCode::string as POSTALCODE,
s.value:state::string as STATE,
s.value:streetAddress::string as STREETADDRESS,
s.value:surname::string as SURNAME,
s.value:userPrincipalName::string as USERPRINCIPALNAME,
s.value:userType::string as USERTYPE,
s.value 

from source as s, lateral flatten(input=> s.value:businessPhones ) f