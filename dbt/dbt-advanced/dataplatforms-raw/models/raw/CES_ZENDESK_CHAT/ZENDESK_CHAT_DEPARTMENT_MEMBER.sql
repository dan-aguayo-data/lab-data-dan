{%- set trimmed_source_rel = model.name | replace("ZENDESK_CHAT_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

SELECT * FROM
{{ source('CES_ZENDESK_CHAT_PROD', 'DEPARTMENT_MEMBER') }}