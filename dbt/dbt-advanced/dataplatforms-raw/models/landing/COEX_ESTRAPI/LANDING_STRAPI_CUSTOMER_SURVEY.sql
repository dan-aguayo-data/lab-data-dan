{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source AS (
    SELECT *
    FROM
        {{ source('SNOWPIPE_PROD', 'COEX_ESTRAPI') }}
    WHERE
        lower(FILE_NAME) LIKE lower('%/strapi-survey/%')
)
SELECT 
        s.MESSAGE:id::bigint as  ID,
        s.MESSAGE:source::string as  SOURCE,
        s.MESSAGE:rating::bigint as  RATING,
        s.MESSAGE:reasons::string as  REASONS,
        s.MESSAGE:comment::string as  COMMENT,
        s.MESSAGE:crp::string as  CRP,
        s.MESSAGE:schemeId::string as  SCHEMEID,
        s.MESSAGE:transactionId::string as  TRANSACTIONID,
        s.MESSAGE:refundAmount::float as  REFUNDAMOUNT,
        s.MESSAGE:transactionDate::datetime as  TRANSACTIONDATE,
        s.MESSAGE:recommendScore::string as  RECOMMENDSCORE,
        s.MESSAGE:referredBy::string as  REFERREDBY,
        s.MESSAGE:whyParticipate::string as  WHYPARTICIPATE,
        s.MESSAGE:crpVisits::string as  CRPVISITS,
        s.MESSAGE:otherComments::string as  OTHERCOMMENTS,
        s.MESSAGE:created_at::datetime as  CREATED_AT,
        s.MESSAGE:updated_at::datetime as  UPDATED_AT,
        s.MESSAGE:waitTime::string as  WAITTIME,
        s.MESSAGE:siteNumber::string as  SITENUMBER

FROM    source as s