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
    lateral flatten(input => s.message:Job_Details[0]:more_custom_fields_detail) f

)
select 
  
  s.FILE_NAME,
  s.message:Job_Details[0]:Job_Id::bigint as JOB_ID,
  s.value:id::bigint as ID,
  s.value:Name::string as NAME,
  s.value:fieldType::bigint as FIELDTYPE,
  s.value:dropDownData::string as DROPDOWNDATA,
  s.value:Value::string as VALUE,
  s.value:loadScreen::bigint as LOADSCREEN,
  s.value:unloadScreen::bigint as UNLOADSCREEN

from source as s