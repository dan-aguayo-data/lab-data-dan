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
  null::string AS MATERIAL_SALES_REF_ID,
  null::string AS SELLER_ID,
  null::string AS BUYER_ID,
  null::string AS MATERIAL_TYPE_ID,
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
  null::string AS DESTINATION_COUNTRY,
  null::bigint AS WEIGHT_IN_KILOGRAMS,
  null::bigint AS NUMBER_OF_BLOCKS,
  null::string AS MATERIAL_SOURCE,
  null::date AS SOLD_ON,
  null::bigint AS DIRECT_SALE_MODE,
  null::string AS CREATED_BY,
  null::timestamp_ntz AS CREATED_ON
WHERE 0=1
