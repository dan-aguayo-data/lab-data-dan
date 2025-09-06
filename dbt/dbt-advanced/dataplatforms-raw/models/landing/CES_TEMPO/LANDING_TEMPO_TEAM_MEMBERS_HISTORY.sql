{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}



WITH ALL_FILES as (

    SELECT *
    FROM {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
    where lower(FILE_NAME) like lower('TEAM_MEMBERS/%')
),   
source as (
  SELECT *
  FROM ALL_FILES s,
  lateral flatten(input => s.message:results) f
) ,
deduped as (
SELECT

    LEFT(s.file_name, 21) AS folder_name,
    s.file_name,
    s.landed_datetime,   
    date((CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Sydney', s.landed_datetime))) as landed_datetime_SYD,
    s.value:member:accountId::string as ACCOUNTID,
    s.value:member:displayName::string as DISPLAYNAME,
    s.value:memberships:active:commitmentPercent::bigint as COMMITMENTPERCENT,
    nullif(s.value:memberships:active:from,'')::date as ACTIVE_FROM,
    nullif(s.value:memberships:active:to,'')::date as ACTIVE_TO,
    s.value:memberships:active:id::bigint as ACTIVE_ID,
    s.value:memberships:active:role:id::bigint as ROLE_ID,
    s.value:memberships:active:role:name::string as ROLE_NAME,
        case when s.value:team:self like 'https://api.tempo.io/4%' then split_part(s.value:team:self,'/',6)::string when s.value:team:self like 'https://api.tempo.io/core%' then  split_part(s.value:team:self,'/',7)::string else 'error' end as TEAM_ID
FROM source as s
QUALIFY ROW_NUMBER() OVER ( PARTITION BY  LEFT(s.file_name, 21),s.value:member:accountId::string,case when s.value:team:self like 'https://api.tempo.io/4%' then split_part(s.value:team:self,'/',6)::string when s.value:team:self like 'https://api.tempo.io/core%' then  split_part(s.value:team:self,'/',7)::string else 'error' end ORDER BY date((CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Sydney', s.landed_datetime)))  DESC) = 1
) , max_min_date_account_team as (
SELECT
    ACCOUNTID AS ACCOUNT_ID_GROUP, 
    TEAM_ID AS TEAM_ID_GROUP,
    MAX(landed_datetime_SYD) team_end_datetime_SYD,
    min(landed_datetime_SYD) team_start_datetime_SYD
from deduped
group by
    ACCOUNTID, 
    TEAM_ID
),
with_validity AS (
    SELECT 
    F.FOLDER_NAME AS FILE_NAME, 
    F.LANDED_DATETIME, 
    F.LANDED_DATETIME_SYD, 
    F.ACCOUNTID, 
    F.DISPLAYNAME, 
    F.COMMITMENTPERCENT, 
    F.ACTIVE_ID, 
    F.ROLE_ID, 
    F.ROLE_NAME, 
    F.TEAM_ID, 
    F.ACTIVE_FROM ACTIVE_SOURCE, 
    F.ACTIVE_TO ACTIVE_TO_SOURCE,
    G.team_start_datetime_SYD AS TEAM_ACTIVE_FROM,
    G.team_end_datetime_SYD AS TEAM_ACTIVE_TO,
    MIN(F.LANDED_DATETIME_SYD) OVER (PARTITION BY F.ACCOUNTID) AS ACCOUNT_ACTIVE_FROM,
    MAX(F.LANDED_DATETIME_SYD) OVER (PARTITION BY F.ACCOUNTID) AS ACCOUNT_ACTIVE_TO,
    F.LANDED_DATETIME_SYD AS FILE_RECORD_VALID_FROM,
    LEAD(DATEADD(DAY,-1,F.LANDED_DATETIME_SYD),1,G.team_end_datetime_SYD) OVER ( PARTITION BY F.ACCOUNTID,F.TEAM_ID ORDER BY F.LANDED_DATETIME_SYD) AS FILE_RECORD_VALID_TO
    FROM deduped F
    LEFT JOIN max_min_date_account_team G
    ON F.ACCOUNTID = G.ACCOUNT_ID_GROUP 
    AND F.TEAM_ID = G.TEAM_ID_GROUP
)
    SELECT *
    FROM with_validity
ORDER BY landed_datetime_SYD desc