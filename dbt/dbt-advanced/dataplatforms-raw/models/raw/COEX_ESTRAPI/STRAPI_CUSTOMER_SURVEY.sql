{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'id'
    )
}}

WITH SOURCE as (

    SELECT
        *
    FROM
        {{ ref('LANDING_STRAPI_CUSTOMER_SURVEY') }}
) 
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(UPDATED_AT, current_date) >= (select max(UPDATED_AT) from {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.id ORDER BY s.UPDATED_AT DESC) = 1