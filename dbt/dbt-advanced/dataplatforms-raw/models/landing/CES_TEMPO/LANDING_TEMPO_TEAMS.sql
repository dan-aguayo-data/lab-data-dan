{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (
    SELECT *
    FROM 
      {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
    where lower(FILE_NAME) = 
    (select lower(FILE_NAME) from   {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }} where lower(FILE_NAME) like lower('TEAMS/%')
    QUALIFY row_number() OVER (PARTITION BY 'TEAMS' ORDER BY LANDED_DATETIME DESC, lower(FILE_NAME) DESC) = 1 )
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
)
  SELECT
    s.value:id::bigint as ID,
    s.value:lead:accountId::string as ACCOUNTID,
    s.value:lead:displayName::string as DISPLAYNAME,
    s.value:name::string as name,
    s.value:program:name::string as PROGRAM_NAME,
    s.value:summary::string as SUMMARY
FROM source as s