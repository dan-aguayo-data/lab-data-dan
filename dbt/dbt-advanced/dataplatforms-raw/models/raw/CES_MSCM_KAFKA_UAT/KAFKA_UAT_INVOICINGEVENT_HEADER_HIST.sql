

{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}


{{
    config(
        alias= trimmed_source_rel,
        enabled = run_flag_exclude_all()
    )  
}}


 WITH source AS (

SELECT * FROM {{ source('CES_MSCM_KAFKA_UAT', 'INVOICINGEVENT_HIST') }}

), INVOICINGEVENT_FLATTEN AS (
    SELECT
        RECORD_CONTENT:"id"::STRING AS KAFKA_ID,
        RECORD_CONTENT:"data"::OBJECT:"BusinessUnit"::STRING AS BUSINESS_UNIT,
        RECORD_CONTENT:"data"::OBJECT:"Description"::STRING AS DESCRIPTION,
        RECORD_CONTENT:"data"::OBJECT:"InvoiceAmount"::NUMBER(38,2) AS INVOICE_AMOUNT,
        RECORD_CONTENT:"data"::OBJECT:"InvoiceCurrency"::STRING AS INVOICE_CURRENCY,
        RECORD_CONTENT:"data"::OBJECT:"InvoiceDate"::DATE AS INVOICE_DATE,
        RECORD_CONTENT:"data"::OBJECT:"InvoiceSource"::STRING AS INVOICE_SOURCE,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 1) AS COMPANY_CODE,
        RECORD_CONTENT:"data"::OBJECT:"LegalEntity"::STRING AS LEGAL_ENTITY,
        RECORD_CONTENT:"data"::OBJECT:"PayAloneFlag"::BOOLEAN AS PAY_ALONE_FLAG,
        RECORD_CONTENT:"data"::OBJECT:"PayGroup"::STRING AS PAY_GROUP,
        RECORD_CONTENT:"data"::OBJECT:"PaymentMethod"::STRING AS PAYMENT_METHOD,
        RECORD_CONTENT:"data"::OBJECT:"PaymentTerms"::STRING AS PAYMENT_TERMS,
        RECORD_CONTENT:"data"::OBJECT:"Supplier"::STRING AS SUPPLIER_NUMBER,
        RECORD_CONTENT:"data"::OBJECT:"SupplierSite"::STRING AS SITE_NUMBER,
        RECORD_CONTENT:"datetime"::TIMESTAMP AS KAFKA_DATETIME,
        RECORD_CONTENT:"source"::STRING AS SOURCE,
        RECORD_CONTENT:"subject"::STRING AS SUBJECT,
        RECORD_CONTENT:"type"::STRING AS TYPE,
        id.VALUE:"paymentNumber"::STRING AS PAYMENT_NUMBER,
        id.VALUE:"posTransactionDate"::DATE AS POS_TRANSACTION_DATE,
        id.VALUE:"posTransactionId"::STRING AS POS_TRANSACTION_ID,
        id.VALUE:"refundPoint"::STRING AS REFUND_POINT,
        ii.VALUE:"DueDate"::DATE AS DUE_DATE,
        ii.VALUE:"GrossAmount"::NUMBER(38,2) AS INSTALLMENT_AMOUNT,
        ii.VALUE:"InstallmentNumber"::NUMBER AS INSTALLMENT_NUMBER,
        ii.VALUE:"PaymentMethod"::STRING AS INSTALLMENT_PAYMENT_METHOD
    FROM source as s,
    LATERAL FLATTEN(INPUT => PARSE_JSON(RECORD_CONTENT:"data"."invoiceInstallments"), OUTER => TRUE) ii,
    LATERAL FLATTEN(INPUT => PARSE_JSON(RECORD_CONTENT:"data"."invoiceDff"), OUTER => TRUE) id,
    LATERAL FLATTEN(INPUT => PARSE_JSON(RECORD_CONTENT:"data"."invoiceLines"), OUTER => TRUE) il,
    LATERAL FLATTEN(INPUT => PARSE_JSON(il.VALUE:"invoiceDistributions"), OUTER => TRUE) dist
    ) 
    SELECT 
    inv.KAFKA_ID,
    inv.BUSINESS_UNIT,
    msi.MULTI_SCHEME_ID,
    inv.DESCRIPTION,
    inv.INVOICE_AMOUNT,
    inv.INVOICE_CURRENCY,
    inv.INVOICE_DATE,
    inv.INVOICE_SOURCE,
    MAX(inv.COMPANY_CODE) AS COMPANY_CODE, --requested by Lyon 4-09-2024
    inv.LEGAL_ENTITY,
    inv.PAY_ALONE_FLAG,
    inv.PAY_GROUP,
    inv.PAYMENT_METHOD,
    inv.PAYMENT_TERMS,
    inv.SUPPLIER_NUMBER,
    inv.SITE_NUMBER,
    inv.KAFKA_DATETIME,
    inv.SOURCE,
    inv.SUBJECT,
    inv.TYPE,
    inv.PAYMENT_NUMBER,
    inv.POS_TRANSACTION_DATE,
    inv.POS_TRANSACTION_ID,
    inv.REFUND_POINT,
    inv.DUE_DATE,
    inv.INSTALLMENT_AMOUNT,
    inv.INSTALLMENT_NUMBER,
    inv.INSTALLMENT_PAYMENT_METHOD

    FROM INVOICINGEVENT_FLATTEN inv

       LEFT JOIN (SELECT DISTINCT x.BUSINESS_UNIT, x.MULTI_SCHEME_ID
    FROM (
    SELECT DISTINCT BUSINESS_UNIT, MULTI_SCHEME_ID FROM   {{ source('CES_MSCM_ORACLE', 'INVOICE_AP_TXN_HDR') }}
    UNION
    SELECT DISTINCT BUSINESS_UNIT, MULTI_SCHEME_ID FROM  {{ source('CES_MSCM_ORACLE', 'INV_AP_INVOICES_INT') }}
    ) x ) msi 
    ON UPPER(msi.business_unit) = UPPER(inv.business_unit)

    GROUP BY
    inv.KAFKA_ID,
    inv.BUSINESS_UNIT,
    msi.MULTI_SCHEME_ID,
    inv.DESCRIPTION,
    inv.INVOICE_AMOUNT,
    inv.INVOICE_CURRENCY,
    inv.INVOICE_DATE,
    inv.INVOICE_SOURCE,
    inv.LEGAL_ENTITY,
    inv.PAY_ALONE_FLAG,
    inv.PAY_GROUP,
    inv.PAYMENT_METHOD,
    inv.PAYMENT_TERMS,
    inv.SUPPLIER_NUMBER,
    inv.SITE_NUMBER,
    inv.KAFKA_DATETIME,
    inv.SOURCE,
    inv.SUBJECT,
    inv.TYPE,
    inv.PAYMENT_NUMBER,
    inv.POS_TRANSACTION_DATE,
    inv.POS_TRANSACTION_ID,
    inv.REFUND_POINT,
    inv.DUE_DATE,
    inv.INSTALLMENT_AMOUNT,
    inv.INSTALLMENT_NUMBER,
    inv.INSTALLMENT_PAYMENT_METHOD


    QUALIFY row_number() OVER (PARTITION BY inv.KAFKA_ID ORDER BY inv.KAFKA_DATETIME DESC) = 1