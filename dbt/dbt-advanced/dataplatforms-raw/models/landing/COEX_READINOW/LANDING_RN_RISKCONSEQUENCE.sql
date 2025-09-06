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
        lower(FILE_NAME) LIKE lower('%/rn_riskconsequence/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE,  
        s.value:lid::string as  LID,
        s.value:name::string as  NAME,
        s.value:typeOfConsequence[0]::string as  TYPE_OF_CONSEQUENCE,
        s.message:type:application:name::string as  APPLICATION_NAME,      
        s.value,
        s.message
FROM    source as s