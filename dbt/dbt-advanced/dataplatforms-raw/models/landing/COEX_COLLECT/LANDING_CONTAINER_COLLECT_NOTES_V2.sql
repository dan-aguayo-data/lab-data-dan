{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}
{%- if  target.name == "UAT" -%} 
    
   
{{  
    config(
        alias=trimmed_source_rel,
        schema = 'COEX_COLLECT_UAT',
        database = 'LANDING'
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
      where lower(FILE_NAME) like lower('dev/collect-extracts-v2-uat/landing/%')
      QUALIFY row_number() OVER (PARTITION BY 'COLLECT' ORDER BY LANDED_DATETIME DESC) = 1
    ) 
), flatten as (
  
   select f.* from source s, 
   lateral flatten(input => s.VALUE:notes) f
 
)
SELECT 
    s.value:id::string as ID,
    s.value:booking::string as BOOKING,
    s.value:comment::string as COMMENT,
    nullif(s.value:createdAt,'')::TIMESTAMP_NTZ as CREATEDAT,
    nullif(s.value:updatedAt,'')::TIMESTAMP_NTZ as UPDATEDAT,
    s.value
FROM flatten as s
    
{%- else -%} 


{{  
    config(
        alias=trimmed_source_rel,
        schema = 'COEX_COLLECT_PROD',
        database = 'LANDING'
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
    where lower(FILE_NAME) like lower('dev/collect-extracts-v2/landing/%')
    and LANDED_DATETIME > to_timestamp('2025-02-08 07:48:46.871', 'YYYY-MM-DD HH24:MI:SS.FF')

), flatten as (
  
   select f.* from source s, 
   lateral flatten(input => s.VALUE:notes) f
 
)
SELECT 
    s.value:id::string as ID,
    s.value:booking::string as BOOKING,
    s.value:comment::string as COMMENT,
    nullif(s.value:createdAt,'')::TIMESTAMP_NTZ as CREATEDAT,
    nullif(s.value:updatedAt,'')::TIMESTAMP_NTZ as UPDATEDAT,
    s.value
FROM flatten as s

{%- endif -%}