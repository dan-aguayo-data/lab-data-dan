{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_ALLOTRAC') }}
)
select 
            
  s.FILE_NAME,
  s.value:locationCoordintes::string as LOCATIONCOORDINATES,
  s.value:Job_Details[0]:Job_Id::bigint as JOB_ID,
  s.value:driverId::bigint as DRIVERID,
  s.value:driverName::string as DRIVERNAME,
  s.value:truckId::bigint as TRUCKID,
  s.value:truckIdentifier::string as TRUCKIDENTIFIER,
  s.value:vehicleclass::string as VEHICLECLASS,
  nullif(s.value:timeStamp,'')::TIMESTAMP_NTZ as TIMESTAMP,
  s.value:jobStatus::bigint as JOBSTATUS,
  s.value:siteName::string as SITENAME,
  s.value:activity::string as ACTIVITY,
  s.value:activity_details::string as ACTIVITY_DETAILS,
  s.value:Source::string as SOURCE,
  s.value
  
from source as s