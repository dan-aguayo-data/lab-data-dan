{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ABN'
    )
}}

WITH SOURCE AS (
    SELECT
        *
    FROM
        {{ ref('LANDING_ABN_EXTRACT') }}
)
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(ABR_recordLastUpdatedDate, current_date) >= (SELECT max(ABR_recordLastUpdatedDate) FROM {{this}})    
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.ABN ORDER BY s.ABR_recordLastUpdatedDate DESC) = 1