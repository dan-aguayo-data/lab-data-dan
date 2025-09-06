{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (
    SELECT *
    FROM 
      {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
    where lower(FILE_NAME) = 
    (select lower(FILE_NAME) from   {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }} where lower(FILE_NAME) like lower('PROJECTS/%')
    QUALIFY row_number() OVER (PARTITION BY 'PROJECTS' ORDER BY LANDED_DATETIME DESC, lower(FILE_NAME) DESC) = 1 )
),   
source as (

  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f
    
)
  SELECT
    s.value:budget:amount:currencyCode::string as BUDGET_AMOUNT_CURRENCYCODE,
    s.value:budget:amount:value::float as BUDGET_AMOUNT_VALUE,
    s.value:defaultBillingRate:currencyCode::string as DEFAULTBILLINGRATE_CURRENCYCODE,
    s.value:defaultBillingRate:value::float as DEFAULTBILLINGRATE_VALUE,
    s.value:defaultCostRate:currencyCode::string as DEFAULTCOSTRATE_CURRENCYCODE,
    s.value:defaultCostRate:value::float as DEFAULTCOSTRATE_VALUE,
    s.value:id::string as ID,
    s.value:isTrackingRevenue::string as ISTRACKINGREVENUE,
    s.value:isUsingApproval::string as ISUSINGAPPROVAL,
    s.value:name::string as NAME,
    s.value:owner:id::string as OWNER_ID,
    s.value:scope:source:reference::string as SCOPE_SOURCE_REFERENCE,
    s.value:scope:source:title::string as SCOPE_SOURCE_TITLE,
    s.value:scope:source:type::string as SCOPE_SOURCE_TYPE,
    s.value:scope:source:url::string as SCOPE_SOURCE_URL,
    s.value:status::string as STATUS
FROM source as s