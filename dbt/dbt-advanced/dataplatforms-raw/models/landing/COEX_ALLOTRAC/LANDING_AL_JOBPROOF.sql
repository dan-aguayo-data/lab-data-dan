{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (
  
    SELECT FILE_NAME, MESSAGE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_ALLOTRAC_JOBPROOF') }}
    
), Flatten_image as (

    SELECT 
    s.FILE_NAME, 
    s.message:JobId::bigint as JOBID,
    f.KEY as STATUS, 
    NVL(f.value:Driver::string, f.value:Consignee::string) as DRIVER, 
    to_timestamp(f.value:Time::string,'DD-MM-YYYY HH:MI:SS') as TIME,
    f.value:Comments::string as COMMENTS, 
    'Image' as URL_TYPE, 
    g.value::string as URL,
    s.message:AdditionalDetail::string as ADDITIONALDETAIL,
    s.MESSAGE
    from source s,
    lateral flatten(input => s.message:Detail) f,
    lateral flatten(input => f.value:image) g
)
, Flatten_sig as (

    SELECT 
    s.FILE_NAME, 
    s.message:JobId::bigint as JOBID,
    f.KEY as STATUS, 
    NVL(f.value:Driver::string, f.value:Consignee::string) as DRIVER, 
    to_timestamp(f.value:Time::string,'DD-MM-YYYY HH:MI:SS') as TIME,
    f.value:Comments::string as COMMENTS, 
    'Signature' as URL_TYPE, 
    g.value::string as URL,
    s.message:AdditionalDetail::string as ADDITIONALDETAIL,
    s.MESSAGE
    from source s,
    lateral flatten(input => s.message:Detail) f,
    lateral flatten(input => f.value:signature) g

) , Flatten_urls as (

    select * from Flatten_image
    UNION ALL
    select * from Flatten_sig

) 
select 
  UPPER(UUID_STRING('7050bc7c-1309-4172-9d6f-f661bdf7a8c8', FILE_NAME||URL)) as ID, * 
from Flatten_urls