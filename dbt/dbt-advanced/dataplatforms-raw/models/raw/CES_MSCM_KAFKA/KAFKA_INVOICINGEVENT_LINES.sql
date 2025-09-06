{%- set trimmed_source_rel = model.name | replace("KAFKA_","") -%}
{%- set src_tbl = "INVOICINGEVENT_LINE_S" if is_incremental() else "INVOICINGEVENT" -%}

{{
    config(
        alias= trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'INVOICE_LINE_ID',
        enabled = run_flag_prod()
    )  
}}
  


WITH source AS (

SELECT * FROM {{ source('CES_MSCM_KAFKA_PROD', src_tbl|string) }}

), INVOICINGEVENT_FLATTEN AS (
    SELECT
        RECORD_CONTENT:"id"::STRING AS KAFKA_ID,
        RECORD_CONTENT:"data"::OBJECT:"InvoiceNumber"::STRING AS INVOICE_NUM,
        CONCAT(RECORD_CONTENT:"data"::OBJECT:"InvoiceNumber"::STRING,'-',il.VALUE:"LineNumber"::STRING) AS INVOICE_LINE_ID,
        RECORD_CONTENT:"datetime"::TIMESTAMP AS KAFKA_DATETIME,
        RECORD_CONTENT:"data"::OBJECT:"BusinessUnit"::STRING AS BUSINESS_UNIT,
        linedff.VALUE::OBJECT:"posTransactionLineId"::STRING AS POS_TRANSACTION_LINE_ID,
        linedff.VALUE::OBJECT:"posMaterialType"::STRING AS POS_MATERIAL_TYPE,
        il.VALUE:"Description"::STRING AS LINE_DESCRIPTION,
        il.VALUE:"LineAmount"::NUMBER(38,2) AS LINE_AMOUNT,
        il.VALUE:"LineNumber"::NUMBER AS LINE_NUMBER,
        il.VALUE:"TaxClassification"::STRING AS TAX_CLASSIFICATION,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 1) AS COMPANY_CODE,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 2) AS MATERIAL_TYPE_CODE,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 3) AS COST_CENTRE_CODE,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 4) AS ACCOUNT_CODE,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 5) AS INTERCOMPANY_CODE,
        SPLIT_PART(dist.VALUE::OBJECT:"DistributionCombination"::STRING, '-', 6) AS SPARE_CODE,
        dist.VALUE::OBJECT:"DistributionAmount"::NUMBER(38,2) AS DISTRIBUTION_AMOUNT,
        dist.VALUE::OBJECT:"DistributionCombination"::STRING AS DISTRIBUTION_COMBINATION,
        dist.VALUE::OBJECT:"DistributionLineNumber"::NUMBER AS DISTRIBUTION_LINE_NUMBER,
        dist.VALUE::OBJECT:"DistributionLineType"::STRING AS DISTRIBUTION_LINE_TYPE
    FROM source as s,
    LATERAL FLATTEN(INPUT => RECORD_CONTENT:"data"."invoiceLines") il,
    LATERAL FLATTEN(INPUT => il.VALUE:"invoiceDistributions") dist,
    LATERAL FLATTEN(INPUT => PARSE_JSON(il.VALUE:"invoiceLineDff"), OUTER => TRUE) linedff 
 
    ) 
    SELECT
    inv.KAFKA_ID,
    inv.INVOICE_NUM,
    inv.INVOICE_LINE_ID,
   -- CONCAT(KAFKA_ID,'-',LINE_NUMBER) AS RECORD_ID,
    inv.KAFKA_DATETIME,
    msi.MULTI_SCHEME_ID,
    inv.POS_TRANSACTION_LINE_ID,
    inv.POS_MATERIAL_TYPE,
    inv.LINE_DESCRIPTION,
    inv.LINE_AMOUNT,
    inv.LINE_NUMBER,
    inv.TAX_CLASSIFICATION,
    inv.COMPANY_CODE,
    inv.MATERIAL_TYPE_CODE,
    inv.COST_CENTRE_CODE,
    inv.ACCOUNT_CODE,
    inv.INTERCOMPANY_CODE,
    inv.SPARE_CODE,
    inv.DISTRIBUTION_AMOUNT,
    inv.DISTRIBUTION_COMBINATION,
    inv.DISTRIBUTION_LINE_NUMBER,
    inv.DISTRIBUTION_LINE_TYPE
    FROM INVOICINGEVENT_FLATTEN inv

     LEFT JOIN (SELECT DISTINCT x.BUSINESS_UNIT, x.MULTI_SCHEME_ID
    FROM (
    SELECT DISTINCT BUSINESS_UNIT, MULTI_SCHEME_ID FROM   {{ source('CES_MSCM_ORACLE', 'INVOICE_AP_TXN_HDR') }}
    UNION
    SELECT DISTINCT BUSINESS_UNIT, MULTI_SCHEME_ID FROM  {{ source('CES_MSCM_ORACLE', 'INV_AP_INVOICES_INT') }}
    ) x ) msi 
    ON UPPER(msi.business_unit) = UPPER(inv.business_unit)

    QUALIFY row_number() OVER (PARTITION BY  inv.INVOICE_LINE_ID  ORDER BY KAFKA_DATETIME DESC) = 1