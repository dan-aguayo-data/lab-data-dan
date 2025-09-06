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
        lower(FILE_NAME) LIKE lower('%/rn_controllibrary/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.value:approvedBy:name::string as  APPROVED_BY,
        s.value:approvedDate::date as  APPROVED_DATE,     
        s.value:approver:name::string as  APPROVER_NAME,
        s.value:category::string as  CATEGORY,
        s.value:controlCategory::string as  CONTROL_CATEGORY,        
        s.value:controlStatus::string as  CONTROL_STATUS,
        s.value:controlType::string as  CONTROL_TYPE,
        s.value:frequency::string as  FREQUENCY,
        s.value:lid::string as  LID, 
        s.value:linkedControls[0]:name::string as  LINKED_CONTROLS_NAME,
        s.value:logEntriesForObject[0]:name::string as  LOG_ENTRIES_FOR_OBJECT_NAME,        
        s.value:name::string as  CONTROL_LIB_NAME,
        s.value:riskLibrary[0]:name::string as  RISK_LIBRARY_NAME,  
        s.value:typeOfControl::string as  TYPE_OF_CONTROL, 
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.value,
        s.message

FROM    source as s