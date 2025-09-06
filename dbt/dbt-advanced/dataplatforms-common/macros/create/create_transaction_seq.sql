{% macro create_transaction_seq() %}

  {% set query %}
    create or replace sequence COMMON_{{ target.name.upper() }}.DWH.CRP_LINK_SEQ_{{ target.name.upper() }} start = 1 increment = 1
  {% endset %}

  {% do run_query(query) %}
{% endmacro %} 