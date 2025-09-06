{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'INCREMENTAL_ID',
        on_schema_change = 'append_new_columns'
    )
}}



WITH TXN_REPROCESS_FAILED AS (

SELECT
H.POS_TXN_NUM
FROM {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS H  --88 K ROWS
INNER JOIN {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS S
ON H.PYMT_TRXN_HEADER_ID = S.PYMT_TRXN_HEADER_ID
AND S.STATUS IN('REPROCESS', 'FAILED PAYPAL BATCH CREATION')
GROUP BY H.POS_TXN_NUM

) {% if is_incremental() %}
, INCREMENTAL_DATE_REF AS (

SELECT DATEADD(HOUR, {{var('general_delta_load_hours')}}, SYSDATE()) AS INCREMENTAL_DELTA

), PYMT_STATUS_INCREMENTAL AS (

SELECT 
pymt.pymt_trxn_header_id
FROM {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PYMT
WHERE UPDATED_ON >= (SELECT  INCREMENTAL_DELTA FROM INCREMENTAL_DATE_REF)

), PYMT_TXN_INCREMENTAL AS (

SELECT
H.POS_TXN_NUM 
FROM
{{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS H
INNER JOIN {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PYMT
ON H.PYMT_TRXN_HEADER_ID = PYMT.PYMT_TRXN_HEADER_ID AND PYMT.UPDATED_ON >= (SELECT  INCREMENTAL_DELTA FROM INCREMENTAL_DATE_REF)
AND PYMT.STATUS IN ('INVOICED','PROCESSED','CLOSED')
WHERE
(H.LAST_MODIFIED_ON >= (SELECT INCREMENTAL_DELTA FROM INCREMENTAL_DATE_REF)
OR PYMT.UPDATED_ON  >= (SELECT INCREMENTAL_DELTA FROM INCREMENTAL_DATE_REF))

) 
{% endif %}

SELECT
PYMT.MULTI_SCHEME_ID  AS MULTI_SCHEME_ID 
, CAST(pymt.pymt_trxn_header_id as varchar(25)) AS ID
, CONCAT('PYMT_TRXN_HEADER_ID','-',TO_CHAR(pymt.pymt_trxn_header_id)) AS INCREMENTAL_ID
, 'PYMT_TRXN_HEADER_ID' AS ID_TYPE
, max(case when status = 'PAID' then 'PAID' ELSE NULL end) AS PAID
, max(case when status = 'VOID' then 'VOID' ELSE NULL end) AS VOID
, max(case when status LIKE '%ERROR%PAID%' then 'PAYMENT ERROR' ELSE NULL end) AS PAYMENT_ERROR
, max(req_approval_flag) AS APPROVAL_FLAG
, max(case when status = 'INVOICED' then 'INVOICED' else NULL end) AS INVOICED
, max(case when status like '%ERROR%INV%' then 'ERROR_INV_ERP' else NULL end) AS ERROR_INV_ERP
, max(case when status like '%ERROR%PAY%' then 'ERROR_PAY_ERP' else NULL end) AS ERROR_PAY_ERP
, max(case when status in ('PROCESSED','CLOSED') then 'ERP PAYMENT COMPLETED' else NULL end) AS ERP_PAYMENT_COMPLETE
, max(case when status = 'NO_VALID_ERP_BNK' then 'NO_VALID_ERP_BNK' else NULL end) AS NO_VALID_ERP_BNK
, max(case when status = 'SENT' then effective_from ELSE NULL end) AS PAID_DATE
, max(case when status IN ('SENT', 'SENDING_PYMT') then effective_from ELSE NULL end) AS ERP_PAID_DATE
, max(case when status IN ('PAID') then effective_from ELSE NULL end) AS FILE_RECEIVED_DATE
, max(case when status = 'VOID' then effective_from ELSE NULL end) AS VOIDED_DATE
, MIN(case when status = 'INVOICED' then effective_from ELSE NULL end) AS INVOICED_DATE
, max(created_on) AS CREATED_ON_UTC
, max(updated_on) AS LAST_MODIFIED_ON_UTC
, SYSDATE() AS INSERT_DATE_UTC
FROM {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PYMT
{% if is_incremental() %}
INNER JOIN PYMT_STATUS_INCREMENTAL PSI
ON TO_CHAR(pymt.pymt_trxn_header_id) = PSI.pymt_trxn_header_id
--WHERE PYMT.UPDATED_ON >= (SELECT  INCREMENTAL_DELTA FROM INCREMENTAL_DATE_REF)  12 - 13 SECS WITH DATE FILTER
{% endif %}
GROUP BY
CAST(PYMT.PYMT_TRXN_HEADER_ID AS VARCHAR(25))
,CONCAT('PYMT_TRXN_HEADER_ID','-',TO_CHAR(pymt.pymt_trxn_header_id))
,PYMT.MULTI_SCHEME_ID
UNION ALL
SELECT
PYMT.MULTI_SCHEME_ID  AS MULTI_SCHEME_ID 
, H.POS_TXN_NUM AS ID
, CONCAT('POS_TXN_NUM','-',TO_CHAR(H.POS_TXN_NUM)) AS INCREMENTAL_ID
, 'POS_TXN_NUM' AS ID_TYPE
, max(case when status = 'PAID' then 'PAID' ELSE NULL end) AS PAID
, max(case when status = 'VOID' then 'VOID' ELSE NULL end) AS VOID
, max(case when status LIKE '%ERROR%PAID%' then 'PAYMENT ERROR' ELSE NULL end) AS PAYMENT_ERROR
, max(req_approval_flag) AS APPROVAL_FLAG
, max(case when status = 'INVOICED' then 'INVOICED' else NULL end) AS INVOICED
, max(case when status like '%ERROR%INV%' then 'ERROR_INV_ERP' else NULL end) AS ERROR_INV_ERP
, max(case when status like '%ERROR%PAY%' then 'ERROR_PAY_ERP' else NULL end) AS ERROR_PAY_ERP
, max(case when status in ('PROCESSED','CLOSED') then 'ERP PAYMENT COMPLETED' else NULL end) AS ERP_PAYMENT_COMPLETE
, max(case when status = 'NO_VALID_ERP_BNK' then 'NO_VALID_ERP_BNK' else NULL end) AS NO_VALID_ERP_BNK
, max(case when status = 'SENT' then effective_from ELSE NULL end) AS PAID_DATE
, max(case when status IN ('SENT', 'SENDING_PYMT') then effective_from ELSE NULL end) AS ERP_PAID_DATE
, max(case when status IN ('PAID') then effective_from ELSE NULL end) AS FILE_RECEIVED_DATE
, max(case when status = 'VOID' then effective_from ELSE NULL end) AS VOIDED_DATE
, MIN(case when status = 'INVOICED' then effective_from ELSE NULL end) AS INVOICED_DATE
, max(pymt.created_on) AS CREATED_ON_UTC
, max(pymt.updated_on) AS LAST_MODIFIED_ON_UTC
, SYSDATE() AS INSERT_DATE_UTC
FROM {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS H
INNER JOIN {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PYMT
ON H.PYMT_TRXN_HEADER_ID = PYMT.PYMT_TRXN_HEADER_ID
AND PYMT.STATUS IN ('INVOICED','PROCESSED','CLOSED')
INNER JOIN TXN_REPROCESS_FAILED F
ON H.POS_TXN_NUM = F.POS_TXN_NUM
{% if is_incremental() %}
INNER JOIN PYMT_TXN_INCREMENTAL PTI
ON H.POS_TXN_NUM = PTI.POS_TXN_NUM
{% endif %}
GROUP BY 
H.POS_TXN_NUM
,CONCAT('POS_TXN_NUM','-',TO_CHAR(H.POS_TXN_NUM))
,PYMT.MULTI_SCHEME_ID