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
    (select lower(FILE_NAME) from   {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }} where lower(FILE_NAME) like lower('TEMPO_TO_JIRA/%')
    QUALIFY row_number() OVER (PARTITION BY 'TEMPO_TO_JIRA' ORDER BY LANDED_DATETIME DESC, lower(FILE_NAME) DESC) = 1 )
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
)
  SELECT
    s.value:jiraWorklogId::string as jiraworklogid,
    s.value:tempoWorklogId::string as tempoWorklogId
    
FROM source as s