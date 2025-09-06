{%- set trimmed_source_rel = model.name | replace("EXT_","") -%}

{{
    config(
        alias=trimmed_source_rel
    )
}}

SELECT
UPPER(UUID_STRING('1050bc7c-1309-4172-9d6f-f551bdf7a8c8', I.UID)) AS "external_id"
, I.EMAIL AS "email"
, I.FIRST_NAME AS "first_name"
, I.LAST_NAME AS "last_name"
, I.SOURCE AS "source"
, I.ADHOC_TYPE AS "adhoc_type"
, I.COMPANY_NAME AS "company_name"
, 'TRUE' AS "adhoc_email_flag"
FROM 
{{ source('COEX_BRAZE', 'BRAZE_ADHOC_EMAILS_IMPORT') }} AS I
QUALIFY ROW_NUMBER() OVER (PARTITION BY I.UID ORDER BY I.UID DESC) = 1