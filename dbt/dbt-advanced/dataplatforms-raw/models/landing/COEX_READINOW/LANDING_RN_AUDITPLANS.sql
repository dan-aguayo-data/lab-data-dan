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
        lower(FILE_NAME) LIKE lower('%/rn_auditplans/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.value:actualEffort::string as  ACTUAL_EFFORT,
        s.value:actualExpenses::string as  ACTUAL_EXPENSES,
        s.value:auditProjectCount::string as  AUDIT_PROJECT_COUNT,
        s.value:auditRegion::string as  AUDIT_REGION,
        s.value:lid::string as  LID,
        s.value:name::string as  AUDIT_PLAN_NAME,
        s.value:owner:name::string as  OWNER_NAME,
        s.value:planStatus::string as  PLAN_STATUS,
        s.value:plannedEffort::string as  PLANNED_EFFORT,
        s.value:plannedExpenses::string as  PLANNED_EXPENSES,
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.value,
        s.message

FROM    source as s