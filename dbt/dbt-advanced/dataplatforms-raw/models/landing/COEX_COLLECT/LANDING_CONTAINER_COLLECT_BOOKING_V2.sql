{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}
{%- if  target.name == "UAT" -%} 
    
{{  
    config(
        alias=trimmed_source_rel,
        schema = 'COEX_COLLECT_UAT',
        database = 'LANDING'
    )
}}


WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
      where lower(FILE_NAME) like lower('dev/collect-extracts-v2-uat/landing/%')
      QUALIFY row_number() OVER (PARTITION BY 'COLLECT' ORDER BY LANDED_DATETIME DESC) = 1
    ) 
)
SELECT 
    s.value:id::string as ID,
    s.value:status::string as STATUS,
    s.value:operatorName::string as OPERATORNAME,
    s.value:createdBy::string as CREATEDBY,
    s.value:scheduledCollection::string as SCHEDULEDCOLLECTION,
    nullif(s.value:date,'')::TIMESTAMP_NTZ as DATE,
    nullif(s.value:collectionWindow:to,'')::TIMESTAMP_NTZ as COLLECTIONWINDOW_TO,
    nullif(s.value:collectionWindow:from,'')::TIMESTAMP_NTZ as COLLECTIONWINDOW_FROM,
    array_to_string(parse_json(s.value:geolocation::string), ', ') as GEOLOCATION,
    s.value:bags:small::string as BAGS_SMALL,
    s.value:bags:medium::string as BAGS_MEDIUM,
    s.value:bags:large::string as BAGS_LARGE,
    s.value:collectionInstructions::string as COLLECTION_INSTRUCTIONS,
    nullif(s.value:createdAt,'')::TIMESTAMP_NTZ as CREATEDAT,
    nullif(s.value:updatedAt,'')::TIMESTAMP_NTZ as UPDATEDAT,
    nullif(s.value:lockedAfter,'')::TIMESTAMP_NTZ as LOCKEDAFTER,
    s.value:address::string as ADDRESS,
    s.value:suburb::string as SUBURB,
    s.value:containersCollected::bigint as CONTAINERSCOLLECTED,
    s.value
FROM source as s
    
{%- else -%} 


{{  
    config(
        alias=trimmed_source_rel,
        schema = 'COEX_COLLECT_PROD',
        database = 'LANDING'
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
    where lower(FILE_NAME) like lower('dev/collect-extracts-v2/landing/%')
    and LANDED_DATETIME > to_timestamp('2025-02-08 07:48:46.871', 'YYYY-MM-DD HH24:MI:SS.FF')
)
SELECT 
    s.value:id::string as ID,
    s.value:status::string as STATUS,
    s.value:operatorName::string as OPERATORNAME,
    s.value:createdBy::string as CREATEDBY,
    s.value:scheduledCollection::string as SCHEDULEDCOLLECTION,
    nullif(s.value:date,'')::TIMESTAMP_NTZ as DATE,
    nullif(s.value:collectionWindow:to,'')::TIMESTAMP_NTZ as COLLECTIONWINDOW_TO,
    nullif(s.value:collectionWindow:from,'')::TIMESTAMP_NTZ as COLLECTIONWINDOW_FROM,
    array_to_string(parse_json(s.value:geolocation::string), ', ') as GEOLOCATION,
    s.value:bags:small::string as BAGS_SMALL,
    s.value:bags:medium::string as BAGS_MEDIUM,
    s.value:bags:large::string as BAGS_LARGE,
    s.value:collectionInstructions::string as COLLECTION_INSTRUCTIONS,
    nullif(s.value:createdAt,'')::TIMESTAMP_NTZ as CREATEDAT,
    nullif(s.value:updatedAt,'')::TIMESTAMP_NTZ as UPDATEDAT,
    nullif(s.value:lockedAfter,'')::TIMESTAMP_NTZ as LOCKEDAFTER,
    s.value:address::string as ADDRESS,
    s.value:suburb::string as SUBURB,
    s.value:containersCollected::bigint as CONTAINERSCOLLECTED,
    s.value
FROM source as s

{%- endif -%}