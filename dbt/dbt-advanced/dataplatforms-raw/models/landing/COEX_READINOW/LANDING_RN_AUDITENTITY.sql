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
        lower(FILE_NAME) LIKE lower('%/rn_auditentity/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.value:auditFrequency::string as  AUDIT_FREQUENCY,
        s.value:auditPlans[0]:name::string as AUDITPLANS_NAME,
        s.value:background::string as  BACKGROUND,
        s.value:lid::bigint as LID,
        s.value:name::string as NAME,
        s.value:roleResponsible:name::string as ROLERESPONSIBLE_NAME,
        s.value,
        s.message
FROM    source as s