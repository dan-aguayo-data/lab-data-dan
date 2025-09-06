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
  WHERE FILE_NAME = (
      SELECT FILE_NAME FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }}
      WHERE lower(FILE_NAME) LIKE lower('users/%')
        QUALIFY row_number() OVER (PARTITION BY 'users' ORDER BY LANDED_DATETIME DESC) = 1
    )
),
source AS (
  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:value) f  
)

SELECT
    s.value:id::string as id 
    ,s.value:displayName::string as displayName
    ,s.value:givenName::string as givenName
    ,s.value:surname::string as surname
    ,s.value:businessPhones::string as businessPhones
    ,s.value:jobTitle::string as jobTitle
    ,s.value:mail::string as mail
    ,s.value:mobilePhone::string as mobilePhone
    ,s.value:officeLocation::string as officeLocation
    ,s.value:preferredLanguage::string as preferredLanguage
    ,s.value:userPrincipalName::string as userPrincipalName
    ,s.value:externalUserState::string as externalUserState
FROM source AS s