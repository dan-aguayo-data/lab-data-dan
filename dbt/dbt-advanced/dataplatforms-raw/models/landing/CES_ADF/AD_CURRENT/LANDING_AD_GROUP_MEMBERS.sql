{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}
{%- set snowpipe_env = "DEV" if target.name.upper() in ["DEV", "UAT"] else "PROD" -%}
{%- set snowpipe_tbl = "CES_ADF_" ~ snowpipe_env -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}
WITH LATEST_FILE AS (
  SELECT *
  FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }}
  WHERE
    FILE_NAME in (
      SELECT FILE_NAME FROM (
        SELECT FILE_NAME FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }}
        WHERE lower(FILE_NAME) LIKE lower('group_members/%')
        QUALIFY row_number() OVER (PARTITION BY CONCAT(split_part(FILE_NAME, '/', 2)) ORDER BY LANDED_DATETIME DESC) = 1) )
    AND LEFT(SPLIT_PART(FILE_NAME, '_', -1),8) = (SELECT MAX(LEFT(SPLIT_PART(FILE_NAME, '_', -1),8)) FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }})
),
source AS (
  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:value) f  
)

SELECT 
    split_part(FILE_NAME, '/', 2) AS GROUP_ID
    ,s.value:displayName::string as displayName
    ,s.value:givenName::string as givenName
    ,s.value:id::string as user_id
    ,s.value:jobTitle::string as jobTitle
    ,s.value:mail::string as mail
    ,s.value:mobilePhone::string as mobilePhone
    ,s.value:officeLocation::string as officeLocation
    ,s.value:preferredLanguage::string as preferredLanguage
    ,s.value:surname::string as surname
    ,s.value:userPrincipalName::string as userPrincipalName
FROM source AS s