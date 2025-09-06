{%- set trimmed_source_rel = model.name | replace("COEX_ASANA_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

    SELECT
        *
    FROM
        {{ source('COEX_ASANA', 'TEAM') }}