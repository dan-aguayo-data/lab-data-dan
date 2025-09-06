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
    (select lower(FILE_NAME) from   {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }} where lower(FILE_NAME) like lower('WORKLOAD_SCHEMES/%')
    QUALIFY row_number() OVER (PARTITION BY 'WORKLOAD_SCHEMES' ORDER BY LANDED_DATETIME DESC, lower(FILE_NAME) DESC) = 1 )
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
)
  SELECT
    s.value:id::bigint as ID,
    s.value:defaultScheme::string as DEFAULTSCHEME,
    s.value:description::string as DESCRIPTION,
    s.value:memberCount::bigint as MEMBERCOUNT,
    s.value:name::string as NAME
FROM source as s