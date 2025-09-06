SELECT
10000 AS MULTI_SCHEME_ID
, 'QLD' AS SCHEME
, S.ID AS ID
, CONCAT(Id,'-', (CASE value  WHEN '' THEN '01' WHEN 'Cleanliness' THEN '02' WHEN 'Customer service' THEN '03' WHEN 'Directions provided' THEN '04' WHEN 'Location' THEN '05' WHEN 'Onsite signage' THEN '06' WHEN 'Parking' THEN '07' WHEN 'Return process' THEN '08' WHEN 'Service & wait time' THEN '09' WHEN 'Service time' THEN '10' WHEN 'Trading hours' THEN '11' WHEN 'Wait time' THEN '12' ELSE '00' END)) AS COMPLAINT_REASON_ID
, CASE WHEN VALUE = '' THEN 'Other' ELSE VALUE END AS REASON
, S.RATING AS RATING
, CASE value WHEN '' THEN '20' WHEN 'Cleanliness' THEN '02' WHEN 'Customer service' THEN '03' WHEN 'Directions provided' THEN '04' WHEN 'Location' THEN '05' WHEN 'Onsite signage' THEN '06' WHEN 'Parking' THEN '07' WHEN 'Return process' THEN '08' WHEN 'Service & wait time' THEN '09' WHEN 'Service time' THEN '10' WHEN 'Trading hours' THEN '11' WHEN 'Wait time' THEN '12' ELSE '00' END AS REASON_SORT
, SYSDATE() AS INSERT_DATE_UTC
FROM (
    SELECT DISTINCT
    ID,
    RATING,
    REPLACE(VALUE, '""') AS VALUE
    FROM (
        SELECT
        S.ID AS ID
        , S.RATING
        , S.REASONS
        FROM {{ source('COEX', 'STRAPI_CUSTOMER_SURVEY') }} AS S
        UNION ALL
        SELECT
        Concat(RIGHT(Regexp_replace(id, '[^\\d]*'), 8), RIGHT(REPLACE(S.created_at, '.', ''), 5)) AS ID
        , S.RATING
        , S.REASONS
        FROM {{ source('COEX', 'RMC_REVIEW_SURVEY') }} AS S
        QUALIFY ROW_NUMBER() OVER (PARTITION BY Concat(RIGHT(Regexp_replace(id, '[^\\d]*'), 8), RIGHT(REPLACE(S.created_at, '.', ''), 5)) ORDER BY CONVERT_TIMEZONE('UTC', 'Australia/Brisbane', S.UPDATED_AT) DESC) = 1
    ) SURVEY,
    LATERAL FLATTEN(INPUT => SPLIT(REASONS, ','))
) S