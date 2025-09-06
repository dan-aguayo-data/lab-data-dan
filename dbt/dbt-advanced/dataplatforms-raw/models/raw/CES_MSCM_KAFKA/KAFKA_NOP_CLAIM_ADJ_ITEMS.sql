{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "NOPCLAIM_ADJ_ITEMS_S_D" if target.name.upper() == 'DEV' else "NOPCLAIM_ADJ_ITEMS_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "NOPCLAIMEVENTTOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_prod()
    )
}}


WITH NOP AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} s,
    LATERAL FLATTEN (input => parse_json(RECORD_CONTENT), path => 'data.refundItems') f
    WHERE RECORD_CONTENT:type::string ='au.com.ces.nop.claim.adjustment.v1'
  
), NOP_FLATTEN AS (

  SELECT 
      concat(N.RECORD_CONTENT:data:adjustmentId::string, '-', N.value:materialTypeId::string) as ID
    , N.RECORD_CONTENT:data:claim:id::string as CLAIM_ID
    , N.RECORD_CONTENT:data:adjustmentId::string as ADJUSTMENT_ID
    , N.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID
    , N.value:materialTypeId::string as MATERIAL_TYPE_ID
    , N.value:containerCount::number as CONTAINER_COUNT
    , N.RECORD_CONTENT:id::string as KAFKA_ID
    , TO_TIMESTAMP(N.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
  FROM 
  NOP as N
  
)
SELECT * FROM NOP_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1