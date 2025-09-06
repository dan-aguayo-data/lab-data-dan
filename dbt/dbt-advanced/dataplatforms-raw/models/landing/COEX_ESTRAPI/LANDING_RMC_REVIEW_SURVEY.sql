{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (

    SELECT *
    FROM {{ source('SNOWPIPE_PROD', 'COEX_ESTRAPI') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_ESTRAPI') }}
      where lower(FILE_NAME) like lower('%/rmcreviews%')
      QUALIFY row_number() OVER (PARTITION BY 'RMCREVIEW' ORDER BY LANDED_DATETIME DESC) = 1
    )  
)
SELECT 
    MESSAGE:id::string as ID,
    MESSAGE:transactionId::string as TRANSACTION_ID,
    MESSAGE:memberNumber::string as MEMBER_NUMBER,
    MESSAGE:siteName::string as SITE_NAME,
    MESSAGE:siteNumber::string as SITE_NUMBER,
    MESSAGE:source::string as SOURCE,
    MESSAGE:reasons::string as REASONS,
    MESSAGE:comment::string as COMMENT,
    MESSAGE:rating::bigint as RATING,
    MESSAGE:refundAmount::float as REFUND_AMOUNT,
    MESSAGE:whyParticipate::string as WHY_PARTICIPATE,
    nullif(MESSAGE:transactionDate,'')::TIMESTAMP_NTZ as TRANSACTION_DATE,
    nullif(MESSAGE:createdAt,'')::TIMESTAMP_NTZ as CREATED_AT,
    nullif(MESSAGE:updatedAt,'')::TIMESTAMP_NTZ as UPDATED_AT,
    MESSAGE as value
FROM LATEST_FILE 