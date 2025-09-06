{%- set trimmed_source_name = model.name | replace("ERP_STAGE_","") -%}

{{
    config(
        alias= trimmed_source_name,
        materialized = 'table'
    )
}}

SELECT
            PAYMENT_SCHEDULE_ID, RECEIVABLE_APPLICATION_ID, TO_DATE(GL_DATE_AR) GL_DATE_AR, TO_DATE(RECEIPT_DATE) RECEIPT_DATE, AMOUNT_APPLIED,
            DISPLAY_AR, TO_TIMESTAMP(LAST_UPDATE_DATE) LAST_UPDATE_DATE , APPLICATION_TYPE, STATUS
        FROM
       {{ref('ERP_STAGE_AR_TRANSACTIONS_DUE')}}
        where RECEIVABLE_APPLICATION_ID <> 0