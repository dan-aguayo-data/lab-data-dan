{%- set trimmed_source_rel = model.name | replace("TAS_","") -%}

{{  
    config(
        alias=trimmed_source_rel,
        materialized="incremental",
        full_refresh=false
    )
}}

SELECT
  null::string AS NOP_IDENTIFIER,
  null::string AS SHIPMENT_MANIFEST_REF_ID,
  null::string AS PICKUP_ADDRESS,
  null::string AS PICKUP_SUBURB,
  null::string AS PICKUP_STATE,
  null::string AS PICKUP_COUNTRY,
  null::string AS PICKUP_POST_CODE,
  null::string AS DELIVERY_ADDRESS,
  null::string AS DELIVERY_SUBURB,
  null::string AS DELIVERY_STATE,
  null::string AS DELIVERY_COUNTRY,
  null::string AS DELIVERY_POST_CODE,
  null::timestamp_ntz AS GENERATED_ON,
  null::string AS GENERATED_BY,
  null::date AS SHIPMENT_DATE,
  null::string AS CONSIGNMENT_NO,
  null::string AS LICENSE_PLATE_NO,
  null::string AS CARRIER_ID,
  null::bigint AS TRUCK_WEIGHT_EMPTY,
  null::bigint AS TRUCK_WEIGHT_TOTAL,
  null::string AS SHIPPER_UNIT_IDENTIFIER,
  null::string AS SHIPPER_UNIT_TYPE,
  null::bigint AS SHIPPER_UNIT_TOTAL_WEIGHT,
  null::bigint AS SHIPPER_UNIT_CONTAINERS_COUNT_TOTAL,
  null::string AS SHIPPER_UNIT_MATERIAL_TYPE_ID
WHERE 0=1