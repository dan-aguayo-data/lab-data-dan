{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'RECEIPTBARCODE'
    )
}}

WITH SOURCE as (
    SELECT 
    RETAILSTOREID
    ,to_number(POSID) as POSID
    ,to_timestamp(TIMESTAMP, 'YYYYMMDDHHMISS') as TIMESTAMP
    ,RECEIPTBARCODE
    ,to_double(AMOUNT) as AMOUNT
    ,to_number(VERIFYRESPONSE) as VERIFYRESPONSE
    ,to_number(CONSUMERESPONSE) as CONSUMERESPONSE
    ,CASHOUT
    ,LANDED_DATETIME
    FROM {{ source('SNOWPIPE_PROD', 'RETURNIT_COLES_PROD') }}
    WHERE RETAILSTOREID<>'COUNT' 
)
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(s.LANDED_DATETIME, current_date) >= (SELECT dateadd(days, -7, max(LANDED_DATETIME)) FROM {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.RECEIPTBARCODE ORDER BY s.TIMESTAMP desc) = 1

