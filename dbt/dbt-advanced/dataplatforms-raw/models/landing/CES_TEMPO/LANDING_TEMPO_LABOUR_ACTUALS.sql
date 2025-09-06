{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (

    SELECT *
    FROM {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
    where 
     split_part(FILE_NAME,'/',2) =(
      select DISTINCT split_part(FILE_NAME,'/',2) from {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
      where lower(FILE_NAME) like lower('LABOUR_ACTUALS/%')
      QUALIFY row_number() OVER (PARTITION BY 'LABOUR_ACTUALS' ORDER BY landed_datetime DESC) = 1) 
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
) 
  SELECT
    s.value:billableSeconds::bigint as BILLABLESECONDS,
    s.value:billingRate:currencyCode::string as BILLINGRATE_CURRENCYCODE,
    s.value:billingRate:value::float as BILLINGRATE_VALUE,
    s.value:cost:currencyCode::string as COST_CURRENCYCODE,
    s.value:cost:value::float as COST_VALUE,
    s.value:costRate:currencyCode::string as COSTRATE_CURRENCYCODE,
    s.value:costRate:value::float as COSTRATE_VALUE,
    s.value:date::date as DATE,
    s.value:revenue:currencyCode::string as REVENUE_CURRENCYCODE,
    s.value:revenue:value::float as REVENUE_VALUE,
    s.value:timeRecordId::string as TIMERECORDID,
    s.value:timeSpentSeconds::bigint as TIMESPENTSECONDS,
    s.value:user:id::string as USER_ID,
    s.value:user.userLink.linked.ecosystem::string as USER_ECOSYSTEM,
    s.value:user.userLink.linked.originId::string as USER_ORIGIN_ID,
    s.value:worklogId::bigint as WORKLOGID
FROM source as s