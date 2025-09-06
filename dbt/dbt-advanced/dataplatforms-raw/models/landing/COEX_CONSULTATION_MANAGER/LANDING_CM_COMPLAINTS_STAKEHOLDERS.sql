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
        lower(FILE_NAME) LIKE lower('%/cm-complaints-stakeholders/%')
)


SELECT 
        s.value:id::string as ID,
        s.value:startDate::string as STARTDATE,
        s.value:endDate::string as ENDDATE,
        s.value:eventType:name::string as EVENTTYPE_NAME,
        s.value:eventType:id::string as EVENTTYPE_ID,
        s.value as raw_values

FROM    source as s
