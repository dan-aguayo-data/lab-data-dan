{% macro create_transaction_seq() %}

  {% set query %}
    create or replace sequence RAW_DEV.CES_MSCM.CRP_CLAIM_HDR_SEQ start = 1 increment = 1
  {% endset %}

  {% do run_query(query) %}
{% endmacro %} 