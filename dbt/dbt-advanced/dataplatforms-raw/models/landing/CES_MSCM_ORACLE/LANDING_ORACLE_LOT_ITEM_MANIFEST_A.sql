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
    WHERE METADATA:"table-name"='LOT_ITEM_MANIFEST_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:ACTUAL_WEIGHT_KGS,'')::float as ACTUAL_WEIGHT_KGS,
    nullif(N.DATA:LOT_ITEM_ID,'')::string as LOT_ITEM_ID,
    nullif(N.DATA:CARRIER,'')::string as CARRIER,
    nullif(N.DATA:CONSIGNMENT_NO,'')::string as CONSIGNMENT_NO,
    nullif(N.DATA:REGISTRATION_NO,'')::string as REGISTRATION_NO,
    nullif(N.DATA:ACTUAL_BLOCKS,'')::bigint as ACTUAL_BLOCKS,
    nullif(N.DATA:TRANSPORT_UNIT_TYPE,'')::string as TRANSPORT_UNIT_TYPE,
    nullif(N.DATA:TRANSPORT_UNIT_COUNT,'')::bigint as TRANSPORT_UNIT_COUNT,
    nullif(N.DATA:FINAL_MANIFEST,'')::bigint as FINAL_MANIFEST,
    nullif(N.DATA:EMPTY_TRUCK_WEIGHT,'')::float as EMPTY_TRUCK_WEIGHT,
    nullif(N.DATA:EMPTY_CONTAINER_WEIGHT,'')::float as EMPTY_CONTAINER_WEIGHT,
    nullif(N.DATA:TOTAL_TRUCK_WEIGHT,'')::float as TOTAL_TRUCK_WEIGHT,
    nullif(N.DATA:MANIFEST_DATE,'')::TIMESTAMP_NTZ as MANIFEST_DATE,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    nullif(N.DATA:NOTE,'')::string as NOTE,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N