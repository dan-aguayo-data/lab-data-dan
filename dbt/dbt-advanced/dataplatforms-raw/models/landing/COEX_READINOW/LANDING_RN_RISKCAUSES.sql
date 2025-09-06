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
        lateral flatten(input => s.message) f
    WHERE
        lower(FILE_NAME) LIKE lower('%/rn_riskcauses/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE, 
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.message
FROM    source as s