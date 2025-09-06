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
        lower(FILE_NAME) LIKE lower('%/cm-complaints-properties/%')
)


SELECT 
        s.value:id::string as ID,
        s.value:value::string as VALUE,
        s.value:complaint:id::string as COMPLAINT_ID,
        s.value as raw_values

FROM    source as s
