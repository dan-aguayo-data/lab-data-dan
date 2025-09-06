{% if target.name.upper()=='DEV' %}
{{
    config(
        materialized = 'incremental',
        unique_key = 'ID',
        post_hook="MERGE
                INTO {{ this }} trg
                USING (
                        select 
                        ID, 
                        SITE_NUMBER, 
                        COLLECTION_QTY+25 as COLLECTION_QTY, 
                        GROSS_AMOUNT*1.25 as GROSS_AMOUNT, 
                        GST_AMOUNT*1.25 as GST_AMOUNT, 
                        TAXABLE_AMOUNT*1.25 as TAXABLE_AMOUNT, 
                        (CASE 
                        WHEN SITE_NUMBER='WC20061002' THEN 'Test Site2'
                        WHEN SITE_NUMBER='WC20061001' THEN 'Test Site1'
                        WHEN SITE_NUMBER='QC12027110' THEN 'test site 1'
                        WHEN SITE_NUMBER='QC12027194' THEN 'test site 2'
                        WHEN SITE_NUMBER='QC12027187' THEN 'test site 3'
                        END) as SITE_NAME, 
                        'Test Recycler' as SUPPLIER_NAME, 
                        CASE WHEN LEFT(SITE_NUMBER, 2) = 'WC' THEN 'Peter Smith' WHEN LEFT(SITE_NUMBER, 2) = 'QC' THEN 'TEST' END as POS_USER_NAME,
                        CASE WHEN LEFT(SITE_NUMBER, 2) = 'WC' THEN TRANSACTION_DATE WHEN LEFT(SITE_NUMBER, 2) = 'QC' THEN DATEADD(YEAR, 4, TRANSACTION_DATE) END AS TRANSACTION_DATE, 
                        CASE WHEN LEFT(SITE_NUMBER, 2) = 'WC' THEN TRANSACTION_DATE_KEY WHEN LEFT(SITE_NUMBER, 2) = 'QC' THEN TO_CHAR(DATEADD(YEAR, 4, TRANSACTION_DATE), 'YYYYMMDD') END AS TRANSACTION_DATE_KEY, 
                        CASE WHEN LEFT(SITE_NUMBER, 2) = 'WC' THEN TRANSACTION_DATE_UTC WHEN LEFT(SITE_NUMBER, 2) = 'QC' THEN DATEADD(YEAR, 4, TRANSACTION_DATE_UTC) END AS TRANSACTION_DATE_UTC 
                        from {{ this }} where SITE_NUMBER in (
                            'WC20061002',
                            'WC20061001',
                            'QC12027110',
                            'QC12027194',
                            'QC12027187'
                        )
                ) src
                ON (trg.ID = src.ID)
                WHEN MATCHED THEN UPDATE
                set
                trg.COLLECTION_QTY = src.COLLECTION_QTY,
                trg.GROSS_AMOUNT = src.GROSS_AMOUNT,
                trg.GST_AMOUNT = src.GST_AMOUNT,
                trg.TAXABLE_AMOUNT = src.TAXABLE_AMOUNT,
                trg.SITE_NAME = src.SITE_NAME,
                trg.SUPPLIER_NAME = src.SUPPLIER_NAME,
                trg.POS_USER_NAME = src.POS_USER_NAME,
                trg.TRANSACTION_DATE = src.TRANSACTION_DATE,
                trg.TRANSACTION_DATE_KEY = src.TRANSACTION_DATE_KEY,
                trg.TRANSACTION_DATE_UTC = src.TRANSACTION_DATE_UTC
                "
    )
}} 
{% else %}
{{
    config(
        materialized = 'incremental',
        unique_key = 'ID'
    )
}}
{% endif %}

SELECT
HDR.MULTI_SCHEME_ID AS MULTI_SCHEME_ID
, SCHEME.NAME AS SCHEME
, HDR.ID AS ID
, '-' AS LINK_ID
, HDR.TRANSACTION_ID AS TRANSACTION_ID
, HDR.EXTERNAL_REFUND_ID AS EXTERNAL_REFUND_ID
, HDR.PAYMENT_METHOD AS PAYMENT_METHOD
, CASE WHEN HDR.PAYMENT_METHOD IN ('BANK', 'SCHEME', 'PAYPAL') THEN 'Scheme' ELSE 'Cash' END AS PAYMENT_TYPE
, HDR.STATUS AS STATUS
, DTL.QUANTITY AS COLLECTION_QTY
, DTL.GROSS_AMOUNT AS GROSS_AMOUNT
, DTL.GST_AMOUNT AS GST_AMOUNT
, DTL.TAXABLE_AMOUNT AS TAXABLE_AMOUNT
, DTL.QUANTITY_INELIGIBLE AS COLLECTION_QTY_INELIGIBLE
, CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(HDR.TRANSACTED_ON AS TIMESTAMP)) AS TRANSACTION_DATE
, NVL(NULLIF(HDR.REFUND_CRP,''),PD.CRP_ID) AS SITE_NUMBER
, PS.SITE_NAME AS SITE_NAME
, PS.POST_CODE AS SITE_POSTCODE
, PS.PARTICIPANT_ID AS SUPPLIER_ID
, P.PARTICIPANT_NUMBER AS SUPPLIER_NUMBER
, P.PARTICIPANT_NAME AS SUPPLIER_NAME
, NVL(NULLIF(NVL(HDR.EXTERNAL_MEMBER_ID, CS.SITE_NUMBER),''), '-') AS CONSUMER_ID
, CS.SITE_NAME AS CONSUMER_NAME
, NVL(R_TT.VALUE, '-') AS CONSUMER_TYPE
, HDR.EXTERNAL_MEMBER_ID AS EXTERNAL_MEMBER_ID
, CASE WHEN CS.SITE_NUMBER IS NULL AND HDR.EXTERNAL_MEMBER_ID IS NULL THEN 'Non-registered' ELSE 'Registered' END AS SCHEME_CONSUMER_FLAG
, CS.POST_CODE AS CONSUMER_POSTCODE
, CASE WHEN CS.SITE_NUMBER = HDR.RECIPIENT_CONSUMER_ID THEN '-' ELSE NVL(NULLIF(HDR.RECIPIENT_CONSUMER_ID,''), '-') END AS RECIPIENT_CONSUMER_ID
, CASE WHEN CP.PARTICIPANT_GROUP_ID IN (1531, 1532, 1533, 2412) THEN CS.SITE_NUMBER ELSE G.CONSUMER_ID_GROUP END AS CONSUMER_ID_GROUP
, CASE WHEN (CASE WHEN CS.SITE_NUMBER = HDR.RECIPIENT_CONSUMER_ID THEN '-' ELSE NVL(NULLIF(HDR.RECIPIENT_CONSUMER_ID,''), '-') END) = '-' AND (CASE WHEN CP.PARTICIPANT_GROUP_ID IN (1531, 1532, 1533, 2412) THEN CS.SITE_NUMBER ELSE G.CONSUMER_ID_GROUP END) = NVL(NULLIF(CS.SITE_NUMBER,''), '-') THEN 1 WHEN (CASE WHEN CP.PARTICIPANT_GROUP_ID IN (1531, 1532, 1533, 2412) THEN CS.SITE_NUMBER ELSE G.CONSUMER_ID_GROUP END) = (CASE WHEN CS.SITE_NUMBER = HDR.RECIPIENT_CONSUMER_ID THEN '-' ELSE NVL(NULLIF(HDR.RECIPIENT_CONSUMER_ID,''), '-') END) THEN 1 ELSE 0 END AS GROUP_TRANSACTION_FLAG
, HDR.POS_DEVICE_ID AS POS_DEVICE_ID
, NVL(HDR.DEVICE_NAME, PD.NAME) AS DEVICE_NAME
, PU.POS_USER_NAME AS POS_USER_NAME
, CASE WHEN DTL.QUANTITY <= 824 THEN ' 0 -  824' WHEN DTL.QUANTITY BETWEEN 825 AND 1500 THEN ' 825 - 1500' WHEN DTL.QUANTITY > 1500 THEN '1500 +' END AS TRANSACTION_BANDING
, TO_CHAR(CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(HDR.TRANSACTED_ON AS TIMESTAMP)),'YYYYMMDD') AS TRANSACTION_DATE_KEY
, TO_CHAR(CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(HDR.TRANSACTED_ON AS TIMESTAMP)),'HHMISS') AS TRANSACTION_TIME_KEY
, HDR.TRANSACTED_ON AS TRANSACTION_DATE_UTC
, CASE WHEN TO_CHAR(CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(HDR.TRANSACTED_ON AS TIMESTAMP)),'YYYYMMDD') = TO_CHAR(CONVERT_TIMEZONE('UTC', 'Australia/NSW', SYSDATE()), 'YYYYMMDD') THEN 1 ELSE 0 END AS CURRENT_DAY_FLAG
, HDR.REFUND_CRP AS REFUND_CRP
, PD.CRP_ID AS SITE_NUMBER_POS
, HDR.PHYSICAL_CONTAINER_RETURN_POINT AS PHYSICAL_CONTAINER_RETURN_POINT
, HDR.BAG_LABEL_ID AS BAG_LABEL_ID
, CASE REPLACE(REPLACE(LOWER(TRIM(BAG_ISSUE_TYPE)), 'scheme id', 'member no.'), '  ', ' ') WHEN 'no issue' THEN 'no bag issue' WHEN 'contain ineligible containers' THEN 'contains ineligible containers' WHEN 'bag contains rubbish/hazardous material' THEN 'bag contains rubbish / hazardous material' WHEN 'bag ripped � no containers' THEN 'bag ripped - no containers' WHEN 'bag ripped � has containers' THEN 'bag ripped - has containers' WHEN 'lids on containers, contains ineligible containers, bag contains rubbish / hazardous material' THEN 'bag contains rubbish / hazardous material, contains ineligible containers, lids on containers' WHEN 'lids on containers, contains ineligible containers' THEN 'contains ineligible containers, lids on containers' WHEN 'lids on containers, cannot scan barcode - manual member no. entered' THEN 'cannot scan barcode - manual member no. entered, lids on containers' WHEN 'lids on containers, bag ripped - has containers' THEN 'bag ripped - has containers, lids on containers' WHEN 'lids on containers, bag contains rubbish / hazardous material, contains ineligible containers' THEN 'bag contains rubbish / hazardous material, contains ineligible containers, lids on containers' WHEN 'lids on containers, bag contains rubbish / hazardous material' THEN 'bag contains rubbish / hazardous material, lids on containers' WHEN 'contains ineligible containers, lids on containers, bag contains rubbish / hazardous material' THEN 'bag contains rubbish / hazardous material, contains ineligible containers, lids on containers' WHEN 'contains ineligible containers, bag ripped - has containers' THEN 'bag ripped - has containers, contains ineligible containers' WHEN 'contains ineligible containers, bag contains rubbish / hazardous material, lids on containers' THEN 'bag contains rubbish / hazardous material, contains ineligible containers, lids on containers' WHEN 'contains ineligible containers, bag contains rubbish / hazardous material' THEN 'bag contains rubbish / hazardous material, contains ineligible containers' WHEN 'bag ripped - has containers, lids on containers, contains ineligible containers' THEN 'bag ripped - has containers, contains ineligible containers, lids on containers' WHEN 'bag ripped - has containers, bag contains rubbish / hazardous material, lids on containers' THEN 'bag contains rubbish / hazardous material, bag ripped - has containers, lids on containers' WHEN 'bag ripped - has containers, bag contains rubbish / hazardous material' THEN 'bag contains rubbish / hazardous material, bag ripped - has containers' WHEN 'bag contains rubbish / hazardous material, lids on containers, contains ineligible containers, bag ripped - has containers' THEN 'bag contains rubbish / hazardous material, bag ripped - has containers, contains ineligible containers, lids on containers' WHEN 'bag contains rubbish / hazardous material, lids on containers, contains ineligible containers' THEN 'bag contains rubbish / hazardous material, contains ineligible containers, lids on containers' WHEN 'bag contains rubbish / hazardous material, cannot scan barcode - manual member no. entered, bag ripped - no containers, lids on containers' THEN 'bag contains rubbish / hazardous material, bag ripped - no containers, cannot scan barcode - manual member no. entered, lids on containers' ELSE REPLACE(REPLACE(LOWER(TRIM(BAG_ISSUE_TYPE)), 'scheme id', 'member no.'), '  ', ' ') END AS BAG_ISSUE_TYPE
, HDR.BAG_ISSUE_DESC AS BAG_ISSUE_DESC
{% if target.name.upper() == 'UAT' %}
, CASE WHEN HDR.BAG_LABEL_ID IS NULL AND HDR.BAG_ISSUE_TYPE IS NOT NULL THEN 'No Bag Label' WHEN HDR.BAG_LABEL_ID IS NULL AND HDR.BAG_ISSUE_TYPE IS NULL THEN 'OTC' ELSE 'Bag Label Scanned' END AS SCHEME_TRANSACTION_TYPE
{%- else -%}
, CASE WHEN HDR.MULTI_SCHEME_ID LIKE '10002%' THEN NULL ELSE CASE WHEN HDR.BAG_LABEL_ID IS NULL AND HDR.BAG_ISSUE_TYPE IS NOT NULL THEN 'No Bag Label' WHEN HDR.BAG_LABEL_ID IS NULL AND HDR.BAG_ISSUE_TYPE IS NULL THEN 'OTC' ELSE 'Bag Label Scanned' END END AS SCHEME_TRANSACTION_TYPE
{% endif %}
, HDR.PHOTO_ID AS PHOTO_ID
, PIT.NAME AS PHOTO_ID_TYPE
, '###' AS PHOTO_ID_NUMBER
, HDR.PHOTO_ID_NAME AS PHOTO_ID_NAME
, HDR.CUSTOMER_DECLARATION AS CUSTOMER_DECLARATION
, HDR.TRANSACTED_BY AS TRANSACTED_BY
, HDR.TRANSACTION_SUBMITTED_BY AS TRANSACTION_SUBMITTED_BY
, HDR.NOTIFIED AS NOTIFIED
, UPPER(TRIM(NVL(CS.POST_CODE, RS.POST_CODE))) AS TRANSACTION_POSTCODE
, NVL(NCR.LATE_SYNC, 'false') AS LATE_SYNC
, HDR.CREATED_BY AS CREATED_BY
, HDR.CREATED_ON AS CREATED_ON_UTC
, HDR.LAST_MODIFIED_BY AS LAST_MODIFIED_BY
, HDR.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC
, SYSDATE() AS INSERT_DATE_UTC
FROM (
    SELECT
    HEADER.MULTI_SCHEME_ID,
    HEADER.ID,
    CASE WHEN COUNT(1) OVER (PARTITION BY HEADER.TRANSACTION_ID) = 1 THEN HEADER.TRANSACTION_ID ELSE HEADER.ID END AS TRANSACTION_ID,
    HEADER.EXTERNAL_REFUND_ID,
    HEADER.EXTERNAL_MEMBER_ID,
    HEADER.PAYMENT_METHOD,
    HEADER.STATUS,
    HEADER.TRANSACTED_BY,
    HEADER.TRANSACTION_SUBMITTED_BY,
    HEADER.TRANSACTED_ON,
    HEADER.REFUND_CRP,
    HEADER.CONSUMER_ID,
    HEADER.RECIPIENT_CONSUMER_ID,
    HEADER.POS_DEVICE_ID,
    HEADER.DEVICE_NAME,
    HEADER.BAG_LABEL_ID,
    HEADER.BAG_ISSUE_TYPE,
    HEADER.BAG_ISSUE_DESC,
    HEADER.PHOTO_ID,
    HEADER.PHOTO_ID_TYPE,
    HEADER.PHOTO_ID_NUMBER,
    HEADER.PHOTO_ID_NAME,
    HEADER.CUSTOMER_DECLARATION,
    HEADER.NOTIFIED,
    HEADER.PHYSICAL_CONTAINER_RETURN_POINT,
    HEADER.CREATED_BY,
    HEADER.CREATED_ON,
    HEADER.LAST_MODIFIED_BY,
    HEADER.LAST_MODIFIED_ON 
    FROM (
        SELECT
        H.MULTI_SCHEME_ID,
        H.ID || '-CRP' AS ID,
        H.ID AS TRANSACTION_ID,
        NULL AS EXTERNAL_REFUND_ID,
        NULL AS EXTERNAL_MEMBER_ID,
        H.PAYMENT_METHOD,
        NULL AS STATUS,
        H.TRANSACTED_BY,
        NULL AS TRANSACTION_SUBMITTED_BY,
        H.TRANSACTED_ON,
        H.REFUND_CRP,
        CASE WHEN H.MULTI_SCHEME_ID <> C.MULTI_SCHEME_ID THEN H.CONSUMER || '002' ELSE H.CONSUMER END AS CONSUMER_ID,
        NVL(CASE WHEN H.MULTI_SCHEME_ID <> C_R.MULTI_SCHEME_ID AND H.MULTI_SCHEME_ID <> '100020001' THEN H.RECIPIENT_CONSUMER_ID || '002' ELSE H.RECIPIENT_CONSUMER_ID END, '-') AS RECIPIENT_CONSUMER_ID,
        H.POS_DEVICE_ID,
        NULL AS DEVICE_NAME,
        H.BAG_LABEL_ID,
        H.BAG_ISSUE_TYPE,
        NULL AS BAG_ISSUE_DESC,
        H.PHOTO_ID,
        H.PHOTO_ID_TYPE,
        H.PHOTO_ID_NUMBER,
        H.PHOTO_ID_NAME,
        H.CUSTOMER_DECLARATION,
        H.NOTIFIED,
        H.PHYSICAL_CONTAINER_RETURN_POINT,
        H.CREATED_BY,
        H.CREATED_ON,
        H.LAST_MODIFIED_BY,
        H.LAST_MODIFIED_ON 
        FROM {{ source('CES_MSCM', 'CRP_REFUND_TXN_HDR') }} AS H
        LEFT JOIN 
        {% if target.name.upper() == 'UAT' %}
        (select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS C
        {%- else -%}
        {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS C
        {% endif %}
        ON H.CONSUMER = C.SITE_NUMBER
        LEFT JOIN 
        {% if target.name.upper() == 'UAT' %}
        (select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS C_R
        {%- else -%}
        {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS C_R
        {% endif %}
        ON H.RECIPIENT_CONSUMER_ID = C_R.SITE_NUMBER
        UNION ALL
        SELECT
        H.MULTI_SCHEME_ID,
        H.ID || '-C' AS ID,
        H.ID AS TRANSACTION_ID,
        NULL AS EXTERNAL_REFUND_ID,
        NULL AS EXTERNAL_MEMBER_ID,
        H.PAYMENT_METHOD,
        H.STATUS,
        H.TRANSACTED_BY,
        NULL AS TRANSACTION_SUBMITTED_BY,
        H.TRANSACTED_ON,
        H.REFUND_CRP,
        CASE WHEN H.MULTI_SCHEME_ID <> C.MULTI_SCHEME_ID THEN H.CONSUMER_ID || '002' ELSE H.CONSUMER_ID END AS CONSUMER_ID,
        NVL(CASE WHEN H.MULTI_SCHEME_ID <> C_R.MULTI_SCHEME_ID AND H.MULTI_SCHEME_ID <> '100020001' THEN H.RECIPIENT_CONSUMER_ID || '002' ELSE H.RECIPIENT_CONSUMER_ID END, '-') AS RECIPIENT_CONSUMER_ID,
        H.POS_DEVICE_ID,
        NULL AS DEVICE_NAME,
        H.BAG_LABEL_ID,
        H.BAG_ISSUE_TYPE,
        H.BAG_ISSUE_DESC,
        H.PHOTO_ID,
        H.PHOTO_ID_TYPE,
        H.PHOTO_ID_NUMBER,
        H.PHOTO_ID_NAME,
        H.CUSTOMER_DECLARATION,
        H.NOTIFIED,
        H.PHYSICAL_CONTAINER_RETURN_POINT,
        H.CREATED_BY,
        H.CREATED_ON,
        H.LAST_MODIFIED_BY,
        H.LAST_MODIFIED_ON 
        FROM {{ source('CES_MSCM', 'CONSUMER_REFUND_TXN_HDR') }} AS H
        LEFT JOIN 
        {% if target.name.upper() == 'UAT' %}
        (select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS C
        {%- else -%}
        {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS C
        {% endif %}
        ON H.CONSUMER_ID = C.SITE_NUMBER
        LEFT JOIN 
        {% if target.name.upper() == 'UAT' %}
        (select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS C_R
        {%- else -%}
        {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS C_R
        {% endif %}
        ON H.RECIPIENT_CONSUMER_ID = C_R.SITE_NUMBER
        UNION ALL
        SELECT
        CAST(H.MULTI_SCHEME_ID AS NUMBER) AS MULTI_SCHEME_ID,
        H.REFUND_TRANSACTION_ID || '-K' AS ID,
        H.REFUND_TRANSACTION_ID AS TRANSACTION_ID,
        {% if target.name.upper() == 'UAT' %}
        HDR.EXTERNAL_REFUND_ID,
        {%- else -%}
        H.EXTERNAL_REFUND_ID,
        {% endif %}
        HDR.EXTERNAL_MEMBER_ID,
        H.PAYMENT_TYPE AS PAYMENT_METHOD,
        NULL AS STATUS,
        HDR.TRANSACTED_BY,
        HDR.TRANSACTION_SUBMITTED_BY,
        H.TRANSACTED_ON_UTC AS TRANSACTED_ON,
        H.CRP_SITE_NUMBER AS REFUND_CRP,
        CASE WHEN H.MULTI_SCHEME_ID <> C.MULTI_SCHEME_ID THEN NVL(HDR.CUSTOMER_NUMBER, '-') || '002' ELSE NVL(HDR.CUSTOMER_NUMBER, '-') END AS CONSUMER_ID,
        NVL(HDR.RECIPIENT_NUMBER, '-') AS RECIPIENT_CONSUMER_ID,
        NVL(HDR.DEVICE_ID, '-') AS POS_DEVICE_ID,
        NVL(HDR.DEVICE_NAME, '-') AS DEVICE_NAME,
        NULL AS BAG_LABEL_ID,
        NULL AS BAG_ISSUE_TYPE,
        NULL AS BAG_ISSUE_DESC,
        NULL AS PHOTO_ID,
        NULL AS PHOTO_ID_TYPE,
        NULL AS PHOTO_ID_NUMBER,
        NULL AS PHOTO_ID_NAME,
        NULL AS CUSTOMER_DECLARATION,
        NULL AS NOTIFIED,
        NULL AS PHYSICAL_CONTAINER_RETURN_POINT,
        HDR.MODIFIEDBY AS CREATED_BY,
        H.KAFKA_DATETIME AS CREATED_ON,
        HDR.MODIFIEDBY AS LAST_MODIFIED_BY,
        H.KAFKA_DATETIME AS LAST_MODIFIED_ON 
        FROM {{ source('CES_MSCM_KAFKA', 'NOP_CLAIM_REFUND') }} AS H
        LEFT JOIN {{ source('CES_MSCM_KAFKA', 'REFUND_TRANSACTION_HDR') }} AS HDR
        ON H.EXTERNAL_REFUND_ID = HDR.EXTERNAL_REFUND_ID
        AND H.MULTI_SCHEME_ID = HDR.MULTI_SCHEME_ID
        LEFT JOIN 
        {% if target.name.upper() == 'UAT' %}
        (select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS C
        {%- else -%}
        {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS C
        {% endif %}
        ON NVL(HDR.CUSTOMER_NUMBER, '-') = C.SITE_NUMBER
        LEFT JOIN 
        {% if target.name.upper() == 'UAT' %}
        (select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS C_R
        {%- else -%}
        {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS C_R
        {% endif %}
        ON NVL(HDR.RECIPIENT_NUMBER, '-') = C_R.SITE_NUMBER
        WHERE H.MULTI_SCHEME_ID IN (100020002, 100020003, 100030001)
    ) HEADER
) HDR
INNER JOIN (
    SELECT
        C.MULTI_SCHEME_ID,
        C.TRANSACTION_ID || '-CRP' AS ID,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.QUANTITY ELSE 0 END) AS QUANTITY,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.GROSS_AMOUNT ELSE 0 END) AS GROSS_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.GST_AMOUNT ELSE 0 END) AS GST_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.TAXABLE_AMOUNT ELSE 0 END) AS TAXABLE_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID LIKE '%INELIGIBLE%' THEN C.QUANTITY ELSE 0 END) AS QUANTITY_INELIGIBLE
    FROM {{ source('CES_MSCM', 'CRP_REFUND_TXN_DTL') }} AS C
    GROUP BY C.MULTI_SCHEME_ID, C.TRANSACTION_ID || '-CRP'
    UNION ALL
    SELECT
        C.MULTI_SCHEME_ID,
        C.TRANSACTION_ID || '-C' AS ID,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.QUANTITY ELSE 0 END) AS QUANTITY,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.GROSS_AMOUNT ELSE 0 END) AS GROSS_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.GST_AMOUNT ELSE 0 END) AS GST_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.TAXABLE_AMOUNT ELSE 0 END) AS TAXABLE_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID LIKE '%INELIGIBLE%' THEN C.QUANTITY ELSE 0 END) AS QUANTITY_INELIGIBLE
    FROM {{ source('CES_MSCM', 'CONSUMER_REFUND_TXN_DTL') }} AS C
    GROUP BY C.MULTI_SCHEME_ID, C.TRANSACTION_ID || '-C'
    UNION ALL
    SELECT
        C.MULTI_SCHEME_ID,
        C.REFUND_TRANSACTION_ID || '-K' AS ID,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.CONTAINER_COUNT ELSE 0 END) AS QUANTITY,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN C.CONTAINER_COUNT * 0.1 ELSE 0 END) AS GROSS_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN NULL ELSE 0 END) AS GST_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID NOT LIKE '%INELIGIBLE%' THEN NULL ELSE 0 END) AS TAXABLE_AMOUNT,
        SUM(CASE WHEN C.MATERIAL_TYPE_ID LIKE '%INELIGIBLE%' THEN C.CONTAINER_COUNT ELSE 0 END) AS QUANTITY_INELIGIBLE
    FROM {{ source('CES_MSCM_KAFKA', 'NOP_CLAIM_REFUND_ITEMS') }} AS C
    WHERE C.MULTI_SCHEME_ID IN (100020002, 100020003, 100030001)
    GROUP BY C.MULTI_SCHEME_ID, C.REFUND_TRANSACTION_ID || '-K'
) DTL
ON HDR.ID = DTL.ID
AND (HDR.MULTI_SCHEME_ID = DTL.MULTI_SCHEME_ID OR DTL.MULTI_SCHEME_ID = 10002)
LEFT JOIN (
    SELECT
    RTS.REFUND_TXN_ID AS TRANSACTION_ID,
    RTS.VALUE AS POST_CODE
    FROM {{ source('CES_MSCM', 'REFUND_TXN_SURVEY') }} AS RTS
    WHERE RTS.SURVEY_TYPE = 'POSTCODE'
) RS
ON HDR.TRANSACTION_ID = RS.TRANSACTION_ID
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON HDR.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
LEFT JOIN {{ source('CES_MSCM', 'POS_DEVICE') }} AS PD
ON HDR.POS_DEVICE_ID = PD.ID
LEFT JOIN {{ source('CES_MSCM', 'POS_USER') }} AS PU
ON HDR.TRANSACTED_BY = PU.ID
LEFT JOIN 
{% if target.name.upper() == 'UAT' %}
(select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS PS
{%- else -%}
{{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS PS
{% endif %}
ON NVL(NULLIF(HDR.REFUND_CRP,''),PD.CRP_ID) = PS.SITE_NUMBER
LEFT JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANTS') }} AS P
ON PS.PARTICIPANT_ID = P.PARTICIPANT_ID
LEFT JOIN 
{% if target.name.upper() == 'UAT' %}
(select * from {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} QUALIFY row_number() OVER (PARTITION BY site_number ORDER BY last_modified_on DESC) = 1) AS CS
{%- else -%}
{{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS CS
{% endif %}
ON HDR.CONSUMER_ID = CS.SITE_NUMBER
LEFT JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANTS') }} AS CP
ON CS.PARTICIPANT_ID = CP.PARTICIPANT_ID
LEFT JOIN {{ source('CES_MSCM', 'SCHEME_REF_CODES') }} AS R_TT
ON CS.TAXONOMY_TYPE_ID = R_TT.SCHEME_REF_CODES_ID
LEFT JOIN {{ source('CES_MSCM', 'PHOTO_ID_TYPE') }} AS PIT
ON HDR.PHOTO_ID_TYPE = PIT.ID
LEFT JOIN {{ source('CES_MSCM_KAFKA', 'NOP_CLAIM_REFUND') }} AS NCR
ON HDR.TRANSACTION_ID = NCR.REFUND_TRANSACTION_ID
AND NCR.LATE_SYNC = 'true'
LEFT JOIN {{ ref('CONSUMER_GROUP') }} AS G
ON HDR.CONSUMER_ID = G.CONSUMER_ID_INDIVIDUAL
AND TO_CHAR(CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(HDR.TRANSACTED_ON AS TIMESTAMP)),'YYYYMMDD')
BETWEEN TO_CHAR(G.EFFECTIVE_START_DATE_GROUP, 'YYYYMMDD') AND NVL(TO_CHAR(DATEADD(DAY, -1, G.EFFECTIVE_END_DATE_GROUP), 'YYYYMMDD'), '99990101')
WHERE (1=1)
{% if target.name.upper() != 'UAT' %}
AND NVL(NULLIF(HDR.REFUND_CRP,''),PD.CRP_ID) NOT IN (
'WC20000001',
'WC20000003',
'QC10006001',
'QC10006002',
'QC10006003',
'QC10006004',
'QC10006005',
'QC10006006',
'QC10006007',
'QC10006008',
'VAC29071001'
)
AND 
HDR.TRANSACTION_ID NOT IN (
'6252CD065C934B408F636E368373200B',
'B2BC7606D2104F4497FA9F41030985BF',
'D3B98196FEB647BA9F1FEEFE52AF2106',
'37A6647C85C540D5994F715A7C2914E2',
'b992fe4a-29b7-49f5-afc7-e5aedcafec4e' --2bn transaction from VIC Visy
)
{% endif %}
{% if is_incremental() %}
    AND
    NVL(LAST_MODIFIED_ON_UTC, SYSDATE()) >= (select DATEADD(hour, -2, max(LAST_MODIFIED_ON_UTC)) from {{this}})
{% endif %}
{% if target.name.upper() == 'UAT' %}
QUALIFY row_number() OVER (PARTITION BY HDR.ID ORDER BY HDR.LAST_MODIFIED_ON DESC) = 1 
{% endif %}