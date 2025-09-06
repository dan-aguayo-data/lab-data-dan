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
        lower(FILE_NAME) LIKE lower('%/rn_investigation/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.value:assignedTo:name::string as  ASSIGNED_TO,
        s.value:attachments[0]:name::string as  ATTACHMENTS_NAME,
        s.value:crpName::string as  CRP_NAME,
        s.value:dateReceived::date as  DATE_RECEIVED,
        s.value:description::string as  DESCRIPTION,
        s.value:investigationStatus::string as  INVESTIGATION_STATUS,
        s.value:lid::string as  LID,
        s.value:otherRelevantNames::string as  OTHER_RELEVANT_NAMES,
        s.value:receivedFrom::string as  RECEIVED_FROM,
        s.value:recommendedAction::string as  RECOMMENDED_ACTION,
        s.value:region::string as  CRP_REGIONNAME,
        s.value:riskLevel::string as  RISK_LEVEL,
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.value,
        s.message
FROM    source as s