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
        lower(FILE_NAME) LIKE lower('%/rn_risklibrary/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE,
        s.value:approvalStatus::string as  APPROVAL_STATUS,
        s.value:approver:name::string as  APPROVER_NAME,
        s.value:causeFactors::string as  CAUSE_FACTORS,
        s.value:controlLibrary[0]:name::string as  CONTROL_LIBRARY_NAME,
        s.value:createdBy:name::string as  CREATED_BY,
        s.value:lastApprovedBy:name::string as  LAST_APPROVED_BY,
        s.value:lastApprovedDate::date as  LAST_APPROVED_DATE,
        s.value:lid::string as  LID,        
        s.value:logEntriesForObject[0]:name::string as  LOG_ENTRIES_FOR_OBJECT,
        s.value:name::string as  NAME,
        s.value:risk[0]:name::string as  RISK_NAME,
        s.value:riskCategory:name::string as  RISK_CATEGORY,
        s.value:riskCategoryType::string as  RISK_CATEGORY_TYPE,
        s.value:riskLibraryStatus::string as  RISK_LIBRARY_STATUS,
        s.value:approver:name::string as  APPROVER,
        s.value:controlLibrary[0]:name::string as  CONTROL_LIBRARY,
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.value,
        s.message
FROM    source as s