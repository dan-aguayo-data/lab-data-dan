{%- if  target.name == "UAT" -%} 
--UAT needed here because it doesn't have UPDATEDAT column, so code has to be different from incremental below 
        SELECT *
        FROM {{ source('COEX_COLLECT_LANDING', model.name|string) }}

{%- else -%} 

{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID'
    )
}}

    WITH SOURCE AS (

        SELECT *
        FROM {{ source('COEX_COLLECT_LANDING', model.name|string) }}

    )
    SELECT
        s.*
    FROM
        source s
    WHERE (1=1)    
    {% if is_incremental() %}
        AND NVL(UPDATEDAT, current_date) >= (SELECT dateadd(hour, {{ var('inc_offset') }}, max(UPDATEDAT)) FROM {{ this }} )
    {% endif %}
    QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.UPDATEDAT DESC) = 1
    

{%- endif -%} 