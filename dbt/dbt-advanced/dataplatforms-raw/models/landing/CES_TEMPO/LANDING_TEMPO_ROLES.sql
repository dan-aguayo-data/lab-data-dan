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
    (select lower(FILE_NAME) from   {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }} where lower(FILE_NAME) like lower('ROLES/%')
    QUALIFY row_number() OVER (PARTITION BY 'ROLES' ORDER BY LANDED_DATETIME DESC, lower(FILE_NAME) DESC) = 1 )
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
)
  SELECT
    s.value:default::string as DEFAULT,
    s.value:id::bigint as ID,
    s.value:name::string as NAME
FROM source as s