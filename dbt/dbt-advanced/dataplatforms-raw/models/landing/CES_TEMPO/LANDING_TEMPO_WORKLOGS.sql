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
    WHERE
    lower(FILE_NAME)=(
      select lower(FILE_NAME) as FILE_NAME from {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
      where lower(FILE_NAME) like lower('WORKLOGS/%')
      QUALIFY row_number() OVER (PARTITION BY 'WORKLOGS' ORDER BY LANDED_DATETIME DESC) = 1)
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
) 
  SELECT
    s.value:jiraWorklogId::bigint as JIRAWORKLOGID,
    s.value:tempoWorklogId::bigint as TEMPOWORKLOGID,
    s.value:description::string as DESCRIPTION,
    s.value:timeSpentSeconds::bigint as TIMESPENTINSECONDS,
    s.value:billableSeconds::bigint as BILLABLESECONDS,
    nullif(s.value:startDate||' '||s.value:startTime,'')::TIMESTAMP_NTZ as STARTDATETIME,
    nullif(s.value:createdAt,'')::TIMESTAMP_NTZ as CREATEDAT,
    nullif(s.value:updatedAt,'')::TIMESTAMP_NTZ as UPDATEDAT,
    s.value:author:accountId::string as ACCOUNTID,
    s.value:author:displayName::string as DISPLAYNAME,
    s.value:issue:id::string as ISSUEID,
    s.value:issue:key::string as ISSUEKEY
FROM source as s