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
      {{ dbt_utils.generate_surrogate_key(["H.N || M.N || S.N"]) }} as DIM_TIME_KEY
    --Natural Key
    , H.N || M.N || S.N AS TIME_ID

    --Attributes
    , H.N AS HOUR
    , M.N AS MINUTE
    , S.N AS SECOND
    , H.N || ':' || M.N || ':' || S.N AS "TIME"
    , CASE WHEN H.N <= 11 THEN 'AM' ELSE 'PM' END AS AM_PM

    FROM (
        SELECT TO_CHAR(SEQ4(), 'FM00') AS N
        FROM TABLE(GENERATOR(ROWCOUNT => 24))
    ) H
    CROSS JOIN (
        SELECT TO_CHAR(SEQ4(), 'FM00') AS N
        FROM TABLE(GENERATOR(ROWCOUNT => 60))
    ) M
    CROSS JOIN (
        SELECT TO_CHAR(SEQ4(), 'FM00') AS N
        FROM TABLE(GENERATOR(ROWCOUNT => 60))
    ) S
    order by TIME_ID