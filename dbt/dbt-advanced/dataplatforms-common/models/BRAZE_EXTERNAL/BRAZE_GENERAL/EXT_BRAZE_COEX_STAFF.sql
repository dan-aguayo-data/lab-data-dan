{%- set trimmed_source_rel = model.name | replace("EXT_","") -%}

{{
    config(
        alias=trimmed_source_rel
    )
}}

SELECT DISTINCT
UPPER(UUID_STRING('7050bc7c-1309-4172-9d6f-f551bdf7a8c8', SM.COEX_LOGIN_ID)) AS "external_id"
, SM.COEX_LOGIN_ID AS "email"
, SPLIT_PART(SM.FULL_NAME, ' ', 1) AS "first_name"
, SPLIT_PART(SM.FULL_NAME, ' ', -1) AS "last_name"
, SM.MOBILE AS "phone"
, 'TRUE' AS "internal_user_flag"
FROM 
{{ source('COEX_AGILOFT', 'AG_COEX_EMPLOYEE_SECURITY_MAPPING_ALL') }} AS SM
WHERE
SM.MULTI_SCHEME_ID = 10000
AND SM.ACTIVE = 1
AND LOWER(SM.COEX_LOGIN_ID) LIKE '%@containerexchange.com.au'
AND SM.MOBILE IS NOT NULL