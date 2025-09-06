SELECT
UUID.MARKETING_UUID AS EXTERNAL_ID
, DRUPAL.SUBSCRIPTION_GROUP_ID AS SUBSCRIPTION_GROUP_ID
FROM
{{ source('CES_DRUPAL', 'PARTICIPANT_SITES') }} AS PS
INNER JOIN {{ source('CES_DRUPAL', 'PARTICIPANTS') }} AS P
ON P.PARTICIPANT_ID = PS.PARTICIPANT_ID
LEFT JOIN (
    SELECT CR.PARTICIPANT_SITE_ID
        ,C.FIRST_NAME
        ,C.LAST_NAME
        ,C.EMAIL
        ,C.CONTACT_ID
        ,C.MOBILE_PHONE_NUMBER
        ,GREATEST(NVL(C.LAST_MODIFIED_ON, TO_DATE('01/01/1900', 'DD/MM/YYYY')), NVL(CR.LAST_MODIFIED_ON, TO_DATE('01/01/1900', 'DD/MM/YYYY'))) AS LAST_MODIFIED_ON_UTC
    FROM {{ source('CES_DRUPAL', 'CONTACTS') }} AS C
    LEFT JOIN {{ source('CES_DRUPAL', 'CONTACT_ROLES') }} AS CR
    ON C.CONTACT_ID = CR.CONTACT_ID
    WHERE CR.ASSIGNMENT_TYPE = 'SITE'
    AND CR.ROLE_TYPE_CODE = 'AUTHORISED_CONTACT_B2C'
    AND C.PRIMARY = 1
    AND C.ACTIVE = 1
    AND CR.ACTIVE = 1
    AND C.FIRST_NAME IS NOT NULL
    QUALIFY ROW_NUMBER() OVER (PARTITION BY CR.PARTICIPANT_SITE_ID ORDER BY NVL(CR.EFFECTIVE_END_DATE, TO_DATE('01/01/9999', 'DD/MM/YYYY')) DESC) = 1
) CC 
ON PS.PARTICIPANT_SITE_ID = CC.PARTICIPANT_SITE_ID
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON PS.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
LEFT JOIN {{ source('CES_DRUPAL', 'CFC_UUID') }} AS UUID
ON UUID.CONSUMER_NUMBER  = P.CONSUMER_NUMBER AND CC.CONTACT_ID = UUID.CONTACT_ID AND UUID.MULTI_SCHEME_ID = 10000 -- AND UUID.TYPE = 'individual' --9626
INNER JOIN 
            (SELECT 
            P.EMAIL
            , (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\blatest_news\\b', 1) WHEN 1 THEN 'unsubscribed' ELSE '817a38cf-8765-46c8-85c3-cbc61077a281' END) AS subscription_group_id
            FROM {{ source('CES_DRUPAL', 'MARKETING_EMAIL_PREFERENCES') }} AS P WHERE P.CREATED_ON >= '2023-02-17'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.EMAIL ORDER BY DECODE(NVL(LOWER(P.TYPE), ''), 'organisation', 1, 'individual', 2, 99)) = 1
 
            UNION ALL
 
            SELECT 
            P.EMAIL
            , (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\bcompetition_and_promotions\\b', 1) WHEN 1 THEN 'unsubscribed' ELSE '9dfa4d11-b58b-4f22-ae06-1fdaba227662' END) AS subscription_group_id
            FROM {{ source('CES_DRUPAL', 'MARKETING_EMAIL_PREFERENCES') }} AS P WHERE P.CREATED_ON >= '2023-02-17'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.EMAIL ORDER BY DECODE(NVL(LOWER(P.TYPE), ''), 'organisation', 1, 'individual', 2, 99)) = 1
 
            UNION ALL
 
            SELECT 
            P.EMAIL
            , (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\brefund_point\\b', 1) WHEN 1 THEN 'unsubscribed' ELSE '5203681e-da15-4f52-ac27-76bd61868a63' END) AS subscription_group_id
            FROM {{ source('CES_DRUPAL', 'MARKETING_EMAIL_PREFERENCES') }} AS P WHERE P.CREATED_ON >= '2023-02-17'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.EMAIL ORDER BY DECODE(NVL(LOWER(P.TYPE), ''), 'organisation', 1, 'individual', 2, 99)) = 1
 
            UNION ALL
 
            SELECT 
            P.EMAIL
            , (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\bopt_events\\b', 1) WHEN 1 THEN 'unsubscribed' ELSE 'fea1d1e9-c8ef-4d02-aa8d-2ebcb3b9e40d' END) AS subscription_group_id
            FROM {{ source('CES_DRUPAL', 'MARKETING_EMAIL_PREFERENCES') }} AS P WHERE P.CREATED_ON >= '2023-02-17'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.EMAIL ORDER BY DECODE(NVL(LOWER(P.TYPE), ''), 'organisation', 1, 'individual', 2, 99)) = 1
 
            UNION ALL
 
            SELECT 
            P.EMAIL,
            CASE WHEN (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\blatest_news\\b', 1) WHEN 1 THEN 0 ELSE 1 END) +
            (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\bcompetition_and_promotions\\b', 1) WHEN 1 THEN 0 ELSE 1 END) +
            (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\brefund_point\\b', 1) WHEN 1 THEN 0 ELSE 1 END) +
            (CASE REGEXP_COUNT(TO_CHAR(VALUE, 'utf8'), '\\bopt_events\\b', 1) WHEN 1 THEN 0 ELSE 1 END) >= 1 THEN '60d461c6-c8fb-4ffa-9745-c5f926168d2b' ELSE 'unsubscribed'  END AS subscription_group_id
            FROM {{ source('CES_DRUPAL', 'MARKETING_EMAIL_PREFERENCES') }} AS P WHERE P.CREATED_ON >= '2023-02-17'
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.EMAIL ORDER BY DECODE(NVL(LOWER(P.TYPE), ''), 'organisation', 1, 'individual', 2, 99)) = 1
   
) DRUPAL
ON lower(DRUPAL.EMAIL) = lower(CC.EMAIL) AND DRUPAL.SUBSCRIPTION_GROUP_ID <> 'unsubscribed'
WHERE 
PS.MULTI_SCHEME_ID = 10000 --COEX
AND PS.TAXONOMY_TYPE_ID = 'Consumer' 
AND P.PARTICIPANT_GROUP = 'IND_CONSUMER'--Just send to individual customers
AND (LOWER(PS.SITE_NAME) NOT LIKE '%pvt%' AND LOWER(PS.SITE_NAME) NOT LIKE'% test %')  --Test sites
AND CC.EMAIL IS NOT NULL --No email populated
AND PS.SITE_NUMBER <> 'C10625269' --2 customer with same info (exclude customer without transactions)
AND PS.STATE = 'QLD' --Customer address is of another state
AND UUID.MARKETING_UUID is not null