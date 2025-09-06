{%- set trimmed_source_rel = model.name | replace("ZENDESK_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

SELECT * FROM
{{ source('CES_ZENDESK_PROD', 'BRAND') }}