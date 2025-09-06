{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source as (

    SELECT *
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_ALLOTRAC') }} s,
    lateral flatten(input => s.message:Job_Details[0]:items_json) f

)
select 

  s.FILE_NAME,
  nullif(s.value:jobId,'')::bigint as JOBID,
  nullif(s.value:itemID,'')::bigint as ITEMID,
  s.value:itemName::string as ITEMNAME,
  s.value:itemUnit::string as ITEMUNIT,
  nullif(s.value:itemWeight,'')::float as ITEMWEIGHT,
  nullif(s.value:idJobItem,'')::bigint as IDJOBITEM,
  s.value:itemCode::string as ITEMCODE,
  s.value:itemType::string as ITEMTYPE,
  s.value:itemComment::string as ITEMCOMMENT,
  nullif(s.value:"Cost/U",'')::float as COST_U,
  nullif(s.value:"Sell/U",'')::float as SELL_U,
  s.value:Compartment::string as COMPARTMENT,
  nullif(s.value:itemWeight_loaded,'')::float as ITEMWEIGHT_LOADED,
  nullif(s.value:prePickup,'')::float as PREPICKUP,
  nullif(s.value:postPickup,'')::float as POSTPICKUP,
  nullif(s.value:preDelivery,'')::float as PREDELIVERY,
  nullif(s.value:postDelivery,'')::float as POSTDELIVERY,
  s.value:cubicType::string as CUBICTYPE,
  nullif(s.value:cubicMeter,'')::float as CUBICMETER,
  nullif(s.value:cubicMeterUpdated,'')::float as CUBICMETERUPDATED,
  nullif(s.value:kgPerUnitType,'')::float as KGPERUNITTYPE,
  nullif(s.value:accurateWeight,'')::float as ACCURATEWEIGHT,
  nullif(s.value:kgperunit,'')::float as KGPERUNIT,
  nullif(s.value:kgperunitUpdated,'')::bigint as KGPERUNITUPDATED,
  nullif(s.value:itemTracking,'')::bigint as ITEMTRACKING,
  s.value:serialNumber::string as SERIALNUMBER,
  s.value:newSerialNumber::string as NEWSERIALNUMBER,
  s.value:ItemWeight:PerUnit::string as ITEMWEIGHT_PERUNIT,
  s.value:CubicMeasurement:M3:PerUnit::string as CUBICMEASUREMENT_PERUNIT,
  s.value:ProductComments::string as PRODUCTCOMMENTS,
  s.value:Surcharge::string as SURCHARGE,
  array_to_string(parse_json(s.value:ServiceCost), ', ') as SERVICECOST

from source as s