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
    WHERE METADATA:"table-name"='MRF_MTL_BOM_REFERENCE_DTL_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:BOM_HDR_ID,'')::string as BOM_HDR_ID,
    nullif(N.DATA:MATERIAL_TYPE_ID,'')::string as MATERIAL_TYPE_ID,
    nullif(N.DATA:PERCENT_ELIGIBLE_CONTAINER,'')::float as PERCENT_ELIGIBLE_CONTAINER,
    nullif(N.DATA:ELIGIBLE_CONTAINER_PER_KG,'')::float as ELIGIBLE_CONTAINER_PER_KG,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N