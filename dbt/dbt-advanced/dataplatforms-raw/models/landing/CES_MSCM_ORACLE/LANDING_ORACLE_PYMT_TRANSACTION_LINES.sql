{%- set trimmed_source_rel = model.name | replace("LANDING_ORACLE_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH SOURCE AS (
    SELECT
        *
    FROM
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM') }}
    WHERE METADATA:"table-name"='PYMT_TRANSACTION_LINES' AND DATA is not null
)

SELECT
    N.DATA:PYMT_TRXN_LINE_ID::bigint as PYMT_TRXN_LINE_ID,
    N.DATA:PYMT_TRXN_HEADER_ID::bigint as PYMT_TRXN_HEADER_ID,
    N.DATA:LINE_NUM::bigint as LINE_NUM,
    nullif(N.DATA:MATERIAL_TYPE,'')::string as MATERIAL_TYPE,
    nullif(N.DATA:UOM_CODE,'')::string as UOM_CODE,
    nullif(N.DATA:QUANTITY,'')::bigint as QUANTITY,
    nullif(N.DATA:AMOUNT,'')::float as AMOUNT,
    nullif(N.DATA:TAX_CLASSIFICATION,'')::string as TAX_CLASSIFICATION,
    nullif(N.DATA:ORIG_LINE_REFERENCE,'')::string as ORIG_LINE_REFERENCE,
    nullif(N.DATA:ORIG_REFERENCE_TYPE,'')::string as ORIG_REFERENCE_TYPE,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:LAST_UPDATE_LOGIN,'')::string as LAST_UPDATE_LOGIN,
    nullif(N.DATA:MATERIAL_TYPE_ID,'')::bigint as MATERIAL_TYPE_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N