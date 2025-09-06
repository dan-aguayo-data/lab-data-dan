{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source AS (
    SELECT *
    FROM  
        {{ source('SNOWPIPE_PROD', 'COEX_READINOW') }} s,
        lateral flatten(input => s.message:data) f
    WHERE
        lower(FILE_NAME) LIKE lower('%/rn_auditworkpaper/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.value:auditEntities[0]:name::string as  AUDIT_ENTITIES_NAME,
        s.value:auditProject:name::string as  AUDIT_PROJECT_NAME,     
        s.value:auditTests[0]:name::string as  AUDIT_TESTS_NAME, 
        s.value:complete::string as  COMPLETE,          
        s.value:description::string as  DESCRIPTION,
        s.value:estimatedFieldwork::string as  ESTIMATED_FIELD_WORK,   
        s.value:fullyEffective::string as  FULLY_EFFECTIVE, 
        s.value:lid::string as  LID,
        s.value:logEntriesForObject[0]:name::string as  LOG_ENTRIES_FOR_OBJECT_NAME,
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.value,
        s.message

FROM    source as s