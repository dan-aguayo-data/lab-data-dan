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
  s.value:Data:VehicleID::bigint as VEHICLEID,
  s.value:Data:LicencePlate::string as LICENCEPLATE,
  s.value:Data:Available::bigint as AVAILABLE,
  nullif(s.value:Data:RegistrationExpiry,'')::DATE as REGISTRATIONEXPIRY,
  s.value:Data:OdometerReading::float as ODOMETERREADING,
  s.value:Data:Make::string as MAKE,
  s.value:Data:AxleCount::bigint as AXLECOUNT,
  s.value:Data:Capacity::float as CAPACITY,
  s.value:Data:Vin::string as VIN,
  s.value:Data:ClassName::string as CLASSNAME,
  s.value:Data:FleetName::string as FLEETNAME,
  s.value:Data:Identifier::string as IDENTIFIER,
  s.value:Data:AxlesSetup::string as AXLESSETUP,
  s.value:Data:EngineNumber::string as ENGINENUMBER,
  s.value:Data:TrackOdometer::bigint as TRACKODOMETER,
  s.value:Data:CompartmenEnable::bigint as COMPARTMENENABLE,
  s.value:Source::string as SOURCE,
  s.value:activity::string as ACTIVITY,
  s.value:activity_details::string as ACTIVITY_DETAILS,
  s.value:siteName::string as SITENAME,
  nullif(s.value:timeStamp,'')::TIMESTAMP_NTZ as TIMESTAMP

from source as s
where s.value:Data:Vin::string is not null