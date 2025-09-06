{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID'
    )
}}


WITH SOURCE as (

    SELECT 
       RECEIPT_ID||'-'||RECEIPT_BARCODE as ID
      ,SITE_NAME
      ,to_number(DECODE(SITE_NUMBER,'NA',NULL, SITE_NUMBER)) as SITE_NUMBER
      ,to_number(RECEIPT_ID) as RECEIPT_ID
      ,RECEIPT_BARCODE
      ,CAST(CREATED_TIMESTAMP AS TIMESTAMP) as CREATED_TIMESTAMP
      ,CAST(REDEEMED_TIMESTAMP AS TIMESTAMP) as REDEEMED_TIMESTAMP
      ,to_double(VALUE) as VALUE
      ,CURRENCY
      ,LANDED_DATETIME
    FROM {{ source('SNOWPIPE_PROD', 'RETURNIT_RVMS2_PROD') }}

)
SELECT
    s.*
FROM
    source s
{% if is_incremental() %}
WHERE
    NVL(s.LANDED_DATETIME, current_date) >= (SELECT dateadd(days, -7, max(LANDED_DATETIME)) FROM {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.CREATED_TIMESTAMP desc) = 1

