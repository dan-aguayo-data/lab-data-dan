{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source AS (
    SELECT *
    FROM
        {{ source('SNOWPIPE_PROD', 'COEX_CONSULTATION_MANAGER') }} s,
        lateral flatten(input => s.message:results) f
    WHERE
        lower(FILE_NAME) LIKE lower('%/cm-eventaction/%')
)


SELECT  DISTINCT
        s.value:id::string as ID,
        s.value:databaseId::string as DATABASEID,
        s.value:leftHandId::string as LEFTHANDID,
        s.value:rightHandId::string as RIGHTHANDID,
        s.value:deleted::string as DELETED,
        s.value:created::string as CREATED,
        s.value:createdBy:enabled::string as CREATEDBY_ENABLED,
        s.value:createdBy:identityType::string as CREATEDBY_IDENTITYTYPE,
        s.value:createdBy:identifier::string as CREATEDBY_IDENTIFIER,
        s.value:createdBy:displayName::string as CREATEDBY_DISPLAYNAME,
        s.value:modifiedBy:enabled::string as MODIFIEDBY_ENABLED,
        s.value:modifiedBy:identityType::string as MODIFIEDBY_IDENTITYTYPE,
        s.value:modifiedBy:identifier::string as MODIFIEDBY_IDENTIFIER,
        s.value:modifiedBy:displayName::string as MODIFIEDBY_DISPLAYNAME,
        s.value:modified::string as MODIFIED,
        s.value:modifiedEndTime::string as MODIFIEDENDTIME,
        s.value 

FROM    source as s
