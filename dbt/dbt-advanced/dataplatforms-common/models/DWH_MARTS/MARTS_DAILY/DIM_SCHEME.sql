
--############ REFERENCE MART ############--

{{ config(
    post_hook=[
        "ALTER TABLE {{ this }} SET TAG DWH_GOLD.DATA_MART = 'REFERENCE'"
    ]
) 
}}



SELECT
--Key naming convention applied for clarity "<TABLE NAME>_KEY". Dbt Util applied.
--Dimension Key
  {{ dbt_utils.generate_surrogate_key(['SCHEME.MULTI_SCHEME_ID']) }} as DIM_SCHEME_KEY

--Natural Key
, SCHEME.MULTI_SCHEME_ID AS MULTI_SCHEME_ID

--Attributes
, SCHEME.NAME AS SCHEME
, DECODE(MULTI_SCHEME_ID,   10000, 'COEX', 
                            10001, 'WARRRL', 
                            10002, 'VICRETURN', 
                            10003, 'TASRECYCLE', 
                            10004, 'SA', 
                            100020001, 'VIC - RETURNIT', 
                            100020002, 'VIC - VISY', 
                            100020003, 'VIC - TOMRA', 
                            100030001, 'TAS - TOMRA',          
                            NULL
  ) NAME
, SCHEME.TIMEZONE AS TIMEZONE

--Metadata Attributes
, SYSDATE() AS INSERT_UTC_DATETIME

FROM
{{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
 
UNION ALL
 
SELECT
--Dimension Key
  {{ dbt_utils.generate_surrogate_key(["'-1'"]) }} as DIM_SCHEME_KEY

--Natural Key
, -1 AS MULTI_SCHEME_ID

--Attributes
, 'CES' AS SCHEME
, 'CES - SHARED' AS NAME
, 'Australia/Sydney' AS TIMEZONE

--Metadata Attributes
, SYSDATE() AS INSERT_UTC_DATETIME
 
UNION ALL
 
SELECT
--Dimension Key
  {{ dbt_utils.generate_surrogate_key(["'0'"]) }} as DIM_SCHEME_KEY

--Natural Key
, 0 AS MULTI_SCHEME_ID

--Attributes
, 'CES' AS SCHEME
, 'CES - INTERNAL' AS NAME
, 'Australia/Sydney' AS TIMEZONE

--Metadata Attributes
, SYSDATE() AS INSERT_UTC_DATETIME