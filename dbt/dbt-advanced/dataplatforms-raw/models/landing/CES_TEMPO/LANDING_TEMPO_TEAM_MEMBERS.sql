{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (

    SELECT *
    FROM {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
    where 
     split_part(FILE_NAME,'/',2) =(
      select DISTINCT split_part(FILE_NAME,'/',2) from {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
      where lower(FILE_NAME) like lower('TEAM_MEMBERS/%')
      QUALIFY row_number() OVER (PARTITION BY 'TEAM_MEMBERS' ORDER BY landed_datetime DESC) = 1) 
  
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
) 
SELECT
    s.value:member:accountId::string as ACCOUNTID,
    s.value:member:displayName::string as DISPLAYNAME,
    s.value:memberships:active:commitmentPercent::bigint as COMMITMENTPERCENT,
    nullif(s.value:memberships:active:from,'')::date as ACTIVE_FROM,
    nullif(s.value:memberships:active:to,'')::date as ACTIVE_TO,
    s.value:memberships:active:id::bigint as ACTIVE_ID,
    s.value:memberships:active:role:id::bigint as ROLE_ID,
    s.value:memberships:active:role:name::string as ROLE_NAME,
    split_part(s.value:team:self,'/',6)::string as TEAM_ID
FROM source as s