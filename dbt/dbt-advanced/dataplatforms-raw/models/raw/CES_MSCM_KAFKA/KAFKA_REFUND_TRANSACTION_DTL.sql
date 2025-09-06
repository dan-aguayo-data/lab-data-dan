{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "REFUND_TRANSACTION_DTL_S1_D" if target.name.upper() == 'DEV' else "REFUND_TRANSACTION_DTL_S1_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "POS_REFUND_TRANSACTION_TOPIC" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',
        enabled = run_flag_prod()
    )
}}

WITH source AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} s,
    lateral flatten(input => s.RECORD_CONTENT:data:refundItems) f

), REFUND_FLATTEN AS (

    SELECT
     concat(s.RECORD_CONTENT:data:refundTransactionId::string, '-', s.value:materialTypeId::string) as ID
    ,concat(s.RECORD_CONTENT:data:externalRefundId::string, '-', s.value:materialTypeId::string) as ID_EXTERNAL  
    ,s.RECORD_CONTENT:data:multiSchemeId::number as MULTI_SCHEME_ID 
    ,s.RECORD_CONTENT:type::string as TYPE
    ,s.RECORD_CONTENT:id::string as KAFKA_ID
    ,TO_TIMESTAMP(s.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
    ,s.RECORD_CONTENT:data:refundTransactionId::string as REFUND_TRANSACTION_ID
    ,s.value:containerCount::number as CONTAINER_COUNT
    ,s.value:gstAmount::float as GST_AMOUNT
    ,s.value:materialTypeId::string as MATERIAL_TYPE_ID
    ,s.value:taxableAmount::float as TAXABLE_AMOUNT
    ,s.value:totalAmount::float as TOTAL_AMOUNT
    ,s.value:unitPrice::float as UNIT_PRICE
    FROM
    source as s

), REFUND_FLATTEN_UNION as (

    SELECT * FROM REFUND_FLATTEN where TYPE not in ('au.com.ces.refund.noncontracted.customer.v1','au.com.ces.refund.noncontracted.crp.v1')
    QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1
    UNION ALL
    SELECT * FROM REFUND_FLATTEN where TYPE in ('au.com.ces.refund.noncontracted.customer.v1','au.com.ces.refund.noncontracted.crp.v1') 
    {% if is_incremental() %}
    and
       ID_EXTERNAL not in (select ID_EXTERNAL from {{this}} where ID_EXTERNAL is not null)
    {% endif %}      
    QUALIFY row_number() OVER (PARTITION BY ID_EXTERNAL ORDER BY KAFKA_DATETIME) = 1
  
)
SELECT * FROM REFUND_FLATTEN_UNION