{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}

{%- set stream_tbl = "PAYMENT_EVALUATION_S_D" if target.name.upper() == 'DEV' else "PAYMENT_EVALUATION_S_P" -%}
{%- set src_tbl = stream_tbl if is_incremental() else "PAYMENTEVENT" -%}

{{
    config(
        alias=trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'RULE_RESULT_ID',
        enabled = run_flag_prod()
    )
}}

WITH source AS (

    SELECT *
    FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }} s,
    LATERAL FLATTEN (input => parse_json(RECORD_CONTENT), path => 'data.paymentEvaluationResult.ruleResults') f

), PYMT_FLATTEN AS (
SELECT
     s.value:id::string as RULE_RESULT_ID
    ,s.RECORD_CONTENT:data:refundEvent:multiSchemeId::number as MULTI_SCHEME_ID
    ,s.RECORD_CONTENT:data:paymentEvaluationResult:runId::string as RUN_ID
    ,s.value:schemeRuleId::string as SCHEME_RULE_ID
    ,s.value:description::string as DESCRIPTION
    ,s.value:message::string as MESSAGE
    ,s.value:name::string as NAME
    ,s.value:result::string as RESULT
    ,s.value:schemeRuleVersion::number as SCHEME_RULE_VERSION
    ,s.RECORD_CONTENT:type::string as TYPE
    ,s.RECORD_CONTENT:datetime::TIMESTAMP_NTZ as KAFKA_DATETIME
FROM
source as s
)
SELECT * FROM PYMT_FLATTEN
QUALIFY row_number() OVER (PARTITION BY RULE_RESULT_ID ORDER BY KAFKA_DATETIME DESC) = 1