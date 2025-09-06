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
        lower(FILE_NAME) LIKE lower('%/rn_risktrend/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE,
        s.value:createdDate::datetime as  CREATED_DATE,
        s.value:impact::string as IMPACT,
        s.value:lid::string as LID,        
        s.value:likelihood::string as  LIKELIHOOD,        
        s.value:peopleConsequence::string as  PEOPLE_CONSEQUENCE,
        s.value:rating::string as  RATING,
        s.value:updateBy:name::string as  UPDATED_BY,
        s.message:type:application:name::string as  APPLICATION_NAME,
        s.value,
        s.message
FROM    source as s