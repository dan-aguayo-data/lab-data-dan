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
    WHERE METADATA:"table-name"='LOT_ITEM_DELIVERY' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:LOT_ITEM_ID,'')::string as LOT_ITEM_ID,
    nullif(N.DATA:FINAL_ADDRESS,'')::string as FINAL_ADDRESS,
    nullif(N.DATA:FINAL_SUBURB,'')::string as FINAL_SUBURB,
    nullif(N.DATA:FINAL_STATE,'')::string as FINAL_STATE,
    nullif(N.DATA:FINAL_COUNTRY,'')::string as FINAL_COUNTRY,
    nullif(N.DATA:FINAL_POST_CODE,'')::string as FINAL_POST_CODE,
    nullif(N.DATA:FINAL_PHONE_NUMBER,'')::string as FINAL_PHONE_NUMBER,
    nullif(N.DATA:DELIVERY_ADDRESS,'')::string as DELIVERY_ADDRESS,
    nullif(N.DATA:DELIVERY_SUBURB,'')::string as DELIVERY_SUBURB,
    nullif(N.DATA:DELIVERY_STATE,'')::string as DELIVERY_STATE,
    nullif(N.DATA:DELIVERY_COUNTRY,'')::string as DELIVERY_COUNTRY,
    nullif(N.DATA:DELIVERY_POST_CODE,'')::string as DELIVERY_POST_CODE,
    nullif(N.DATA:DELIVERY_PHONE_NUMBER,'')::string as DELIVERY_PHONE_NUMBER,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:DECLARATION,'')::bigint as DECLARATION,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N