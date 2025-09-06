{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}
{%- set snowpipe_env = "DEV" if target.name.upper() in ["DEV", "UAT"] else "PROD" -%}
{%- set snowpipe_tbl = "CES_ADF_" ~ snowpipe_env -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}


WITH LATEST_FILE_LIST AS (
    SELECT DISTINCT
    FILE_NAME
    FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }}
    WHERE 1 = 1
    AND RIGHT(LEFT(SPLIT_PART(FILE_NAME, '_', -1),8),2)  = '01' 
    AND lower(FILE_NAME) LIKE lower('groups/%') 
    QUALIFY ROW_NUMBER() OVER (PARTITION BY LEFT(SPLIT_PART(FILE_NAME, '_', -1),8) ORDER BY LANDED_DATETIME DESC) = 1 
), LATEST_FILE_QUERY  AS ( 
    SELECT A.*
    FROM {{ source('SNOWPIPE', snowpipe_tbl|string) }} A
    INNER JOIN LATEST_FILE_LIST B
    ON A.FILE_NAME = B.FILE_NAME
), source AS (
    SELECT *
    FROM LATEST_FILE_QUERY s,
    lateral flatten(input => s.message:value) f  
)

SELECT LEFT(SPLIT_PART(FILE_NAME, '_', -1),8) AS EXTRACT_DATE, 
    s.value:id::string as id 
    ,s.value:classification::string as classification
    ,s.value:createdDateTime::string as createdDateTime
    ,s.value:deletedDateTime::string as deletedDateTime
    ,s.value:description::string as description
    ,s.value:displayName::string as displayName
    ,s.value:expirationDateTime::string as expirationDateTime
    ,s.value:isAssignableToRole::string as isAssignableToRole
    ,s.value:mail::string as mail
    ,s.value:mailEnabled::string as mailEnabled
    ,s.value:mailNickname::string as mailNickname
    ,s.value:membershipRule::string as membershipRule
    ,s.value:membershipRuleProcessingState::string as membershipRuleProcessingState
    ,s.value:onPremisesDomainName::string as onPremisesDomainName
    ,s.value:onPremisesLastSyncDateTime::string as onPremisesLastSyncDateTime
    ,s.value:onPremisesNetBiosName::string as onPremisesNetBiosName
    ,s.value:onPremisesProvisioningErrors::string as onPremisesProvisioningErrors
    ,s.value:onPremisesSamAccountName::string as onPremisesSamAccountName
    ,s.value:onPremisesSecurityIdentifier::string as onPremisesSecurityIdentifier
    ,s.value:onPremisesSyncEnabled::string as onPremisesSyncEnabled
    ,s.value:preferredDataLocation::string as preferredDataLocation
    ,s.value:preferredLanguage::string as preferredLanguage
    ,s.value:renewedDateTime::string as renewedDateTime
    ,s.value:securityEnabled::string as securityEnabled
    ,s.value:securityIdentifier::string as securityIdentifier
    ,s.value:theme::string as theme
    ,s.value:visibility::string as visibility
FROM source AS s