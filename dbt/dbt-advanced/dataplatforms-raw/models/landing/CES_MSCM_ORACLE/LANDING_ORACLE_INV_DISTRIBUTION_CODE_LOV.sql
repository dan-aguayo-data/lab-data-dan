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
    WHERE METADATA:"table-name"='INV_DISTRIBUTION_CODE_LOV' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    N.DATA:SCHEME_PARTICIPANT_TYPE::string as SCHEME_PARTICIPANT_TYPE,
    N.DATA:INVOICE_TYPE::string as INVOICE_TYPE,
    N.DATA:PAYMENT_GROUP::string as PAYMENT_GROUP,
    N.DATA:MATERIAL_TYPE_NAME::string as MATERIAL_TYPE_NAME,
    N.DATA:MATERIAL_TYPE_ID::string as MATERIAL_TYPE_ID,
    N.DATA:ENTITY::string as ENTITY,
    N.DATA:ACCOUNT_CLASS::string as ACCOUNT_CLASS,
    N.DATA:COST_CENTRE::string as COST_CENTRE,
    N.DATA:NATURAL_ACC::string as NATURAL_ACC,
    N.DATA:INTER_CO_ACC::string as INTER_CO_ACC,
    N.DATA:SPARE::string as SPARE,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N