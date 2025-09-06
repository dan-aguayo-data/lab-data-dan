{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID'
    )
}}

WITH SOURCE as (
    SELECT
        *
    FROM
        {{ ref('LANDING_AL_JOBPROOF') }}

)
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(TIME, current_date) >= (SELECT dateadd(days, -1, max(TIME)) FROM {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.TIME DESC) = 1