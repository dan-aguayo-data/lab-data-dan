{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT *
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_ALLOTRAC') }} s,
    lateral flatten(input => s.message:Job_Details[0]:Stops) f

)
select 
  s.FILE_NAME,
  s.message:Job_Details[0]:Job_Id::bigint as JOB_ID,
  s.value:StopType::string as STOPTYPE,
  s.value:StopNo::bigint as STOPNO,
  s.value:ContactId::string as CONTACTID,
  s.value:AddressId::string as ADDRESSID,
  s.value:AccountName::string as ACCOUNTNAME,
  s.value:CompanyName::string as COMPANYNAME,
  s.value:Address::string as ADDRESS

from source as s