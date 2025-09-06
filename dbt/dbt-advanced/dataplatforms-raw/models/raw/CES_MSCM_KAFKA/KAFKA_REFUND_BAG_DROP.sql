{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "REFUND_BAG_DROP_S_D" if target.name.upper() == 'DEV' else "REFUND_BAG_DROP_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "POSREFUNDSERVICEREFUNDTRANSACTIONTOPIC" -%}

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
    lateral flatten(input => s.RECORD_CONTENT:data:bagDrop:issues) f

), REFUND_FLATTEN AS (

    SELECT
     concat(s.RECORD_CONTENT:data:refundTransactionId::string, '-', s.value:type::string) as ID 
    ,s.RECORD_CONTENT:data:multiSchemeId::number as MULTI_SCHEME_ID
    ,s.RECORD_CONTENT:data:bagDrop:label::string as LABEL
    ,s.value:comment::string as COMMENT
    ,s.value:type::string as TYPE
    ,s.RECORD_CONTENT:data:refundTransactionId::string as REFUND_TRANSACTION_ID
    ,s.RECORD_CONTENT:id::string as KAFKA_ID
    ,TO_TIMESTAMP(s.RECORD_CONTENT:datetime::variant) as KAFKA_DATETIME
    FROM
    source as s
)
SELECT * FROM REFUND_FLATTEN
QUALIFY row_number() OVER (PARTITION BY ID ORDER BY KAFKA_DATETIME DESC) = 1