{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID'
    )
}}


WITH SOURCE as (

    SELECT 
     STORE_NUMBER||'-'||CHECKOUT_NUMBER||'-'||TENDER_BARCODE as ID
    ,to_number(STORE_NUMBER) as STORE_NUMBER
    ,to_number(CHECKOUT_NUMBER) as CHECKOUT_NUMBER
    ,to_timestamp(TRANSACTION_TIMESTAMP_UTC, 'YYYYMMDDHHMISS') as TRANSACTION_TIMESTAMP_UTC
    ,TENDER_BARCODE
    ,to_double(TENDER_AMOUNT) as TENDER_AMOUNT
    ,to_number(VERIFY_STATUS_CODE) as VERIFY_STATUS_CODE
    ,to_number(REDEEM_STATUS_CODE) as REDEEM_STATUS_CODE
    ,CASHOUT_FLAG
    ,LANDED_DATETIME
    FROM {{ source('SNOWPIPE_PROD', 'RETURNIT_WOOLWORTHS_PROD') }}
    WHERE STORE_NUMBER not like '%COUNT%'
)
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(s.LANDED_DATETIME, current_date) >= (SELECT dateadd(days, -7, max(LANDED_DATETIME)) FROM {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.TRANSACTION_TIMESTAMP_UTC desc) = 1

