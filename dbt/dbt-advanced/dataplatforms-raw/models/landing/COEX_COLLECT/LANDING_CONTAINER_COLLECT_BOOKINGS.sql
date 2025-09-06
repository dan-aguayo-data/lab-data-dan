{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_COLLECT') }}
      where lower(FILE_NAME) like lower('dev/collect-extracts/landing/%')
      QUALIFY row_number() OVER (PARTITION BY 'COLLECT' ORDER BY LANDED_DATETIME DESC) = 1
    ) 

)
SELECT 
    s.value:id::bigint as ID,
    s.value:location_id::bigint as LOCATION_ID,
    s.value:scheme_id::string as SCHEME_ID,
    s.value:email::string as EMAIL,
    s.value:first_name::string as FIRST_NAME,
    s.value:last_name::string as LAST_NAME,
    s.value:mobile::string as MOBILE,
    s.value:address::string as ADDRESS,
    s.value:address_type::string as ADDRESS_TYPE,
    s.value:unit::string as UNIT,
    s.value:street::string as STREET,
    s.value:suburb::string as SUBURB,
    s.value:postcode::string as POSTCODE,
    s.value:bag_location::string as BAG_LOCATION,
    nullif(s.value:date,'')::date as DATE,
    s.value:time::string as TIME,
    s.value:bags::bigint as BAGS,
    s.value:refund_type::string as REFUND_TYPE,
    s.value:pickup_status::string as PICKUP_STATUS,
    s.value:bags_collected::bigint as BAGS_COLLECTED,
    s.value:bags_missing::bigint as BAGS_MISSING,
    s.value:booking_source::string as BOOKING_SOURCE,
    s.value:containers_collected::string as CONTAINERS_COLLECTED,
    s.value:notes::string as NOTES,
    nullif(s.value:deleted_at,'')::TIMESTAMP_NTZ as DELETED_AT,
    nullif(s.value:created_at,'')::TIMESTAMP_NTZ as CREATED_AT,
    nullif(s.value:updated_at,'')::TIMESTAMP_NTZ as UPDATED_AT
FROM source as s