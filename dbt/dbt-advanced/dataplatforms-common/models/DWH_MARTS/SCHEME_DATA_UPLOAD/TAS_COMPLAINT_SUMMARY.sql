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
  null::bigint AS ZONE_ID,
  null::string AS bigintERACTION_TYPE,
  null::string AS CHANNEL_TYPE,
  null::bigint AS CATEGORY_TYPE,
  null::bigint AS CUSTOMER_TYPE,
  null::bigint AS AVERAGE_TIME_TO_RESPOND,
  null::bigint AS AVERAGE_TIME_TO_RESOLVE,
  null::bigint AS COUNT_OF_bigintERACTIONS,
  null::bigint AS COUNT_OF_bigintERACTIONS_RESOLVED,
  null::string AS PERIOD_TYPE,
  null::string AS PERIOD
WHERE 0=1