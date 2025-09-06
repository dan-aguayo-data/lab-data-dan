{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}
{%- set snowpipe_env = "DEV" if target.name.upper() in ["DEV", "UAT"] else "PROD" -%}
{%- set snowpipe_tbl = "CES_ADF_" ~ snowpipe_env -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}


WITH FIRSTDAYMONTH_FILES AS (

 SELECT DISTINCT
    FILE_NAME,
    LEFT(SPLIT_PART(FILE_NAME, '_', -1),8) DATE_TEXT,
    CONCAT(split_part(FILE_NAME, '/', 2)) AS GROUP_ID,
    LANDED_DATETIME
    FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }}
    WHERE 1 = 1
    AND RIGHT(LEFT(SPLIT_PART(FILE_NAME, '_', -1),8),2) = '01' 
    AND lower(FILE_NAME) LIKE lower('group_members/%') 

),LATEST_FILE_LIST AS (
    SELECT DISTINCT
    FILE_NAME
    FROM FIRSTDAYMONTH_FILES
    QUALIFY row_number() OVER (PARTITION BY GROUP_ID,DATE_TEXT  ORDER BY LANDED_DATETIME DESC) = 1 
), LATEST_FILE_QUERY  AS ( 
    SELECT A.*
    FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }} A
    INNER JOIN  LATEST_FILE_LIST B
    ON A.FILE_NAME = B.FILE_NAME
    ORDER BY LEFT(SPLIT_PART(FILE_NAME, '_', -1),8) DESC
), source AS (
    SELECT *
    FROM LATEST_FILE_QUERY s,
    lateral flatten(input => s.message:value) f  
)
SELECT LEFT(SPLIT_PART(FILE_NAME, '_', -1),8) AS EXTRACT_DATE,
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
