{%- set trimmed_source_rel = model.name | replace("EXT_","") -%}

{{
    config(
        alias=trimmed_source_rel
    )
}}


WITH CRP_DETAILS AS (
      SELECT 
      U.ID
      , U.SCHEME_PARTICIPANT_TYPE AS "participant_type" --''
      , LISTAGG(DISTINCT L.CRP_TYPE,',') OVER (PARTITION BY CRP.ID) AS "crp_type" --''
      , L.REGION AS "crp_sub_region"
      , L.LOCAL_COUNCIL AS "lga"
      , L.REGIONAL_MANAGER AS "regional_manager"
      , L.BUSINESS_TYPE AS "business_type"
      , L.ELECTORATE AS "electorate"
      FROM(
            SELECT 
            U.ID,
            SUBSTRING(S.VALUE,POSITION(' Q',S.VALUE,1)+1,10) AS CRP_ID
            FROM {{ source('COEX_AGILOFT', 'AG_EXTERNAL_USER') }} AS U
            LEFT JOIN LATERAL flatten(INPUT => U.VALUE:site_access_crp) S
      ) CRP
      LEFT JOIN {{ source('COEX_AGILOFT', 'AG_LOCATION') }} AS L
      ON CRP.CRP_ID = L.SCHEME_SITE_ID  AND NOT(NVL(L.INACTIVE_DATE,TO_DATE('01-01-9999','DD-MM-YYYY')) < SYSDATE())--INACTIVE DATE IN THE FUTURE OR NULL
      FULL JOIN {{ source('COEX_AGILOFT', 'AG_EXTERNAL_USER') }} AS U
      ON U.ID = CRP.ID

      --********* UAT *********--
      {% if target.name.upper() != 'PROD' %}
      WHERE "participant_type" NOT LIKE '%Beverage Manufacturer%' AND "participant_type" NOT LIKE '%Exporter%'
      {% endif %}
      --********* UAT *********--
)

--********* UAT *********--
{% if target.name.upper() != 'PROD' %}
, 
SOURCE AS (
      SELECT
      UPPER(UUID_STRING('7050bc7c-1309-4172-9d6f-f551bdf7a8c8', CONCAT(C.EMAIL, PS.MULTI_SCHEME_ID))) AS "external_id"
      , C.FIRST_NAME AS FIRST_NAME
      , C.LAST_NAME AS LAST_NAME
      , C.PHONE_NUMBER AS PHONE
      , C.EMAIL AS EMAIL
      , C.ACTIVE AS AG_DEACTIVATE_USER
      , R_T.VALUE AS ROLE_TYPE
      , CR.ACTIVE AS ROLE_STATUS
      , R_TT.VALUE AS PARTICIPANT_TYPE
      , PS.SITE_NUMBER
      , PS.SITE_NAME
      , PS.STATUS
      , PS.BAG_DROP_SITE
      , PS.DEPOT_SITE
      , PS.RVM_SITE
      , PS.POP_UP_SITE
      , CS.LGA
      , CS.SITE_CONTRACT_MANAGER_NAME
      , PS.ELECTORATE_LOWER
      , PS.TAXONOMY_SUB_TYPE
      , PS.TAXONOMY_SIZE
      , PS.POST_CODE
      , PR.TRADING_NAME
      , PR.MANUFACTURES_ONLY_WINE_OR_SPIRITS
      , CS.SUBREGION AS crp_subregion
      FROM
      {{ source('CES_MSCM', 'MDT_CONTACTS') }} C
      INNER JOIN (
            SELECT * 
            FROM {{ source('CES_MSCM', 'MDT_CONTACT_ROLES') }} CR
            QUALIFY ROW_NUMBER() OVER (PARTITION BY CR.CONTACT_ID, CR.role_type_id, CR.PARTICIPANT_SITE_ID ORDER BY CR.LAST_MODIFIED_ON DESC) = 1
      ) CR
      ON C.CONTACT_ID = CR.CONTACT_ID
      INNER JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS PS
      ON CR.PARTICIPANT_SITE_ID = PS.PARTICIPANT_SITE_ID
      INNER JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANTS') }} AS P 
      ON PS.PARTICIPANT_ID = P.PARTICIPANT_ID
      LEFT JOIN {{ ref('PARTICIPANT_REGISTRATION') }} AS PR 
      ON PS.PARTICIPANT_ID = PR.PARTICIPANT_ID AND PR.MULTI_SCHEME_ID = PS.MULTI_SCHEME_ID
      LEFT JOIN {{ ref('CRP_SITES') }} AS CS 
      ON PS.MULTI_SCHEME_ID = CS.MULTI_SCHEME_ID AND PS.SITE_NUMBER = CS.SITE_NUMBER
      LEFT JOIN {{ source('CES_MSCM', 'SCHEME_REF_CODES') }} AS R_T 
      ON CR.ROLE_TYPE_ID = R_T.SCHEME_REF_CODES_ID
      LEFT JOIN {{ source('CES_MSCM', 'SCHEME_REF_CODES') }} AS R_TT 
      ON PS.TAXONOMY_TYPE_ID = R_TT.SCHEME_REF_CODES_ID
      WHERE --ROLE_TYPE_ID IN (1106,1947,1105,2189,1108,1101,1104,1102,2382,1103,2190,1107,2191)
      PS.MULTI_SCHEME_ID = 10000
      AND PS.SITE_TYPE_ID <> '1537'
      AND (R_TT.VALUE LIKE '%Beverage Manufacturer%' OR R_TT.VALUE LIKE '%Exporter%')
      AND C.EMAIL NOT IN         
      ('chris.blaney@coexservices.com.au'
      ,'coexfin.claims@gmail.com'
      ,'hayley.pearson@containerexchange.com.au'
      ,'it-test@coexservices.com.au'
      ,'ken.noye@containerexchange.com.au'
      ,'kuva@emergentlearning.com.au'
      ,'p.l.smith.6753@gmail.com'
      ,'pinetree9656@gmail.com'
      ,'reema.sharma@coexservices.com.au'
      ,'pvt_exporter5_21062020@yopmail.com.au'
      ,'coex.livetest1@yahoo.com'
      ,'pvt1@unlocksynergy.com'
      ,'PVT_Exporter6@yopmail.com.au'
      ,'PVT_Exporter5@yopmail.com.au')
)
, USER_ARRAY AS ( 
      SELECT DISTINCT 
      "external_id"
      , EMAIL
      , FIRST_NAME
      , LAST_NAME
      , PHONE
      , AG_DEACTIVATE_USER  
      FROM SOURCE
)
, SITE_ARRAY AS (
      SELECT DISTINCT
      "external_id"
      , EMAIL
      , SITE_NUMBER
      , OBJECT_CONSTRUCT('participant_type', CASE WHEN PARTICIPANT_TYPE IN ('') THEN NULL ELSE PARTICIPANT_TYPE END) AS JSON_PAR_TYPE
      , CASE WHEN PARTICIPANT_TYPE IN ('Beverage Manufacturer', 'Exporter')  THEN
      OBJECT_CONSTRUCT(
            'participant_type', CASE WHEN PARTICIPANT_TYPE IN ('') THEN NULL ELSE PARTICIPANT_TYPE END
            , 'site_number', CASE WHEN trim(SITE_NUMBER) = '' THEN NULL ELSE trim(SITE_NUMBER) END
            , 'site_name', CASE WHEN trim(SITE_NAME) = '' THEN NULL ELSE trim(SITE_NAME) END
            , 'site_status', CASE WHEN trim(STATUS) = '' THEN NULL ELSE trim(STATUS) END
            , 'taxonomy_sub_type', CASE WHEN trim(TAXONOMY_SUB_TYPE) = '' THEN NULL ELSE(TAXONOMY_SUB_TYPE) END
            , 'taxonomy_size', CASE WHEN trim(TAXONOMY_SIZE) = '' THEN NULL ELSE(TAXONOMY_SIZE) END
            , 'postcode', CASE WHEN trim(POST_CODE) = '' THEN NULL ELSE(POST_CODE) END
            , 'wine_or_spirits', CASE WHEN trim(MANUFACTURES_ONLY_WINE_OR_SPIRITS) = '' THEN NULL ELSE(MANUFACTURES_ONLY_WINE_OR_SPIRITS) END
            , 'trading_name', CASE WHEN trim(TRADING_NAME) = '' THEN NULL ELSE(TRADING_NAME) END
      ) ELSE 
      OBJECT_CONSTRUCT(
            'participant_type', CASE WHEN PARTICIPANT_TYPE IN ('') THEN NULL ELSE PARTICIPANT_TYPE END
            , 'site_number', CASE WHEN trim(SITE_NUMBER) = '' THEN NULL ELSE trim(SITE_NUMBER) END
            , 'site_name', CASE WHEN trim(SITE_NAME) = '' THEN NULL ELSE trim(SITE_NAME) END
            , 'site_status', CASE WHEN trim(STATUS) = '' THEN NULL ELSE trim(STATUS) END
      ) END AS JSON_ATTR_TYPE
      FROM SOURCE
)
, ROLE_ARRAY AS (
      SELECT
      "external_id"
      , EMAIL
      , SITE_NUMBER
      , ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT(
            'role_type', CASE WHEN trim(ROLE_TYPE) = '' THEN NULL ELSE trim(ROLE_TYPE) END
            ,'role_status', CASE WHEN trim(ROLE_STATUS) = '' THEN NULL ELSE trim(ROLE_STATUS) END  
      ))) AS JSON_ATTR_ROLE
      FROM SOURCE
      GROUP BY 1,2,3
)
, FINAL AS (
      SELECT SA."external_id"
      , SA.EMAIL
      , UA.FIRST_NAME
      , UA.LAST_NAME
      , UA.PHONE
      , UA.AG_DEACTIVATE_USER
      , SA.JSON_ATTR_TYPE
      , RA.JSON_ATTR_ROLE
      , SA.JSON_PAR_TYPE
      FROM SITE_ARRAY SA
      LEFT JOIN ROLE_ARRAY RA 
      ON SA.SITE_NUMBER=RA.SITE_NUMBER AND RA."external_id"=SA."external_id"
      LEFT JOIN USER_ARRAY UA 
      ON UA."external_id"= SA."external_id" 
)

{% endif %}
--********* UAT *********--


SELECT
UPPER(UUID_STRING('7050bc7c-1309-4172-9d6f-f551bdf7a8c8', U.ID)) AS "external_id"
, U.EMAIL AS "email"
, U.FIRST_NAME AS "first_name"
, U.LAST_NAME AS "last_name"
, CASE WHEN REPLACE(U.DIRECT_PHONE, ' ', '') LIKE '04%' AND LEN(REPLACE(U.DIRECT_PHONE, ' ', '')) = 10 THEN '61' || RIGHT(REPLACE(U.DIRECT_PHONE, ' ', ''),9) ELSE REPLACE(U.DIRECT_PHONE, ' ', '') END AS "phone"
, E.ERP_ID AS "organisation_id"
, MP.ALTERNATE_NAME AS "company_name"
, E.MAIN_ZIP_OR_POSTAL_CODE AS "post_code"
, E.MAIN_CITY AS "suburb"
, E.LATEST_CONTRACT_STATUS AS "contract_status"
, CT.CONTACT_TYPE AS "contact_type"
, CT.TAXONOMY_SUB_TYPE AS "taxonomy_sub_type"
, CT.TAXONOMY_SIZE AS "taxonomy_size"
, CRP_TYPE.JSON_PARTICIPANT_TYPE AS "participant_type"
, CASE WHEN U.ADD_TO_OPERATOR_COMMS = 'Yes' THEN 'TRUE' ELSE 'FALSE' END AS "operator_comms_flag"
, CRP_TYPE.JSON_CRP_TYPE AS "crp_type"
, CRP."crp_sub_region" AS "crp_sub_region"
, CRP."lga" AS "lga"
, CRP."regional_manager" AS "regional_manager"
, CRP."business_type" AS "business_type"
, CRP."electorate" AS "electorate"
, U.DEACTIVATE_USER AS "ag_deactivate_user"
, E.STATUS AS "status"

--********* UAT *********--
{% if target.name.upper() != 'PROD' %}
, NULL AS "bm_details"
{% endif %}
--********* UAT *********--

FROM 
{{ source('COEX_AGILOFT', 'AG_EXTERNAL_USER') }} AS U
LEFT JOIN {{ source('COEX_AGILOFT', 'AG_ENTITY') }} AS E
ON U.COMPANY_ID = E.ID
LEFT JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANTS') }} AS MP
ON MP.PARTICIPANT_NUMBER = E.ERP_ID
LEFT JOIN (
      SELECT B2B.ID
      , ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('crp_type', CASE WHEN trim(A.VALUE) = '' THEN NULL ELSE trim(A.VALUE) END))), [{}]) AS JSON_CRP_TYPE
      , ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('participant_type', CASE WHEN trim(G.VALUE) = '' THEN NULL ELSE trim(G.VALUE) END))) AS JSON_PARTICIPANT_TYPE
      FROM CRP_DETAILS B2B
      , LATERAL SPLIT_TO_TABLE(B2B."crp_type",',')A
      , LATERAL SPLIT_TO_TABLE(B2B."participant_type",',')G
     GROUP BY B2B.ID
) CRP_TYPE
ON CRP_TYPE.ID = U.ID
LEFT JOIN (
      SELECT B2B.ID
      , ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('crp_sub_region', trim(B2B."crp_sub_region")))), [{}]) AS "crp_sub_region"
      , ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('lga', trim(B2B."lga")))), [{}]) AS "lga"
      , ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('regional_manager', trim(B2B."regional_manager")))), [{}]) AS "regional_manager"
      , ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('business_type', trim(B2B."business_type")))), [{}]) AS "business_type"
      , ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('electorate', trim(B2B."electorate")))), [{}]) AS "electorate"
      FROM CRP_DETAILS B2B GROUP BY B2B.ID
) CRP
ON CRP.ID = U.ID
LEFT JOIN (
    SELECT
    C.EMAIL
    ,ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('TAXONOMY_SUB_TYPE', PS.TAXONOMY_SUB_TYPE))), [{}]) AS TAXONOMY_SUB_TYPE
    ,ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('TAXONOMY_SIZE', PS.TAXONOMY_SIZE))), [{}]) AS TAXONOMY_SIZE
    ,ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('ROLE_TYPE_ID', CR.ROLE_TYPE_ID))), [{}]) AS ROLE_TYPE_ID
    ,ARRAY_EXCEPT( ARRAY_DISTINCT(ARRAY_AGG(OBJECT_CONSTRUCT('contact_type', R_T.VALUE))), [{}]) AS CONTACT_TYPE
    FROM 
    {{ source('CES_MSCM', 'MDT_CONTACTS') }} AS C
    INNER JOIN 
    {{ source('CES_MSCM', 'MDT_CONTACT_ROLES') }} AS CR 
    ON C.CONTACT_ID = CR.CONTACT_ID
    INNER JOIN
    {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS PS
    ON CR.PARTICIPANT_SITE_ID = PS.PARTICIPANT_SITE_ID
    LEFT JOIN 
    {{ source('CES_MSCM', 'SCHEME_REF_CODES') }} AS R_T
    ON CR.ROLE_TYPE_ID = R_T.SCHEME_REF_CODES_ID
    WHERE ROLE_TYPE_ID IN (1106,1947,1105,2189,1108,1101,1104,1102,2382,1103,2190,1107,2191)
    AND PS.MULTI_SCHEME_ID = 10000
    AND PS.SITE_TYPE_ID <> '1537'
    AND C.ACTIVE = 1
    AND CR.ACTIVE = 1
    GROUP BY ALL
) CT
ON U.EMAIL = CT.EMAIL
WHERE
U.SCHEME_PARTICIPANT_TYPE IS NOT NULL 

--********* UAT *********--
{% if target.name.upper() != 'PROD' %}
AND CRP_TYPE.JSON_PARTICIPANT_TYPE IS NOT NULL 

UNION ALL

 SELECT
"external_id"
, EMAIL AS "email"
, FIRST_NAME AS "first_name"
, LAST_NAME AS "last_name"
, NULL AS "phone"
, NULL AS "organisation_id"
, NULL AS "company_name"
, NULL AS "post_code"
, NULL AS "suburb"
, NULL AS "contract_status"
, NULL AS "contact_type"
, NULL AS "taxonomy_sub_type"
, NULL AS "taxonomy_size"
, ARRAY_DISTINCT(ARRAY_AGG(JSON_PAR_TYPE)) AS "participant_type"
, NULL AS "operator_comms_flag"
, NULL AS "crp_type"
, NULL AS "crp_sub_region"
, NULL AS "lga"
, NULL AS "regional_manager"
, NULL AS "business_type"
, NULL AS "electorate"
, CASE WHEN ag_deactivate_user = '1' THEN 'True' ELSE 'False' END AS "ag_deactivate_user"
, NULL AS "status"
, ARRAY_DISTINCT(ARRAY_AGG(ARRAY_COMPACT(ARRAY_CONSTRUCT(JSON_ATTR_TYPE, JSON_ATTR_ROLE)))) AS "bm_details"
FROM final
GROUP BY ALL
{% endif %}
--********* UAT *********--


