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
        lower(FILE_NAME) LIKE lower('%/rn_audittest/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.value:auditTestType::string as  AUDIT_TEST_TYPE,
        s.value:auditWorkpaper:name::string as  AUDIT_WORKPAPER_NAME,
        s.value:description::string as  DESCRIPTION,
        s.value:evidenceRequired::string as  EVIDENCE_REQUIRED,
        s.value:lid::string as  LID,
        s.value:name::string as  NAME,
        s.value:order::string as  "ORDER",
        s.value:owner:name::string as  OWNER_NAME,
        s.value:testProcedure::string as  TEST_PROCEDURE,
        s.value,
        s.message

FROM    source as s