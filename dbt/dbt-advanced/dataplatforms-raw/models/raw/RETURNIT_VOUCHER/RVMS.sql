{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID'
    )
}}


WITH SOURCE as (

    SELECT 
     RVM_ID||'-'||RECEIPT_ID as ID
    ,to_number(RVM_ID) as RVM_ID
    ,NAME
    ,CAST(DEPOSITED_ON AS TIMESTAMP) as DEPOSITED_ON
    ,PAYMENT_METHOD
    ,CUSTOMER_ID
    ,to_number(RECEIPT_ID) as RECEIPT_ID
    ,RECEIPT_BARCODE
    ,to_number(COUNT) as COUNT
    ,to_double(VALUE) as VALUE
    ,CAST(REGISTERED_ON AS TIMESTAMP) as REGISTERED_ON
    ,CAST(REDEEMED_TIMESTAMP AS TIMESTAMP) as REDEEMED_TIMESTAMP
    ,LANDED_DATETIME
    FROM {{ source('SNOWPIPE_PROD', 'RETURNIT_RVMS_PROD') }}

)
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(s.LANDED_DATETIME, current_date) >= (SELECT dateadd(days, -7, max(LANDED_DATETIME)) FROM {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.REGISTERED_ON desc) = 1

