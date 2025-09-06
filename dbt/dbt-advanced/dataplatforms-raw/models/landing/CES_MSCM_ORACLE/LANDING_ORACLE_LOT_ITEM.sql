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
    WHERE METADATA:"table-name"='LOT_ITEM' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:AUCTION_EVENT_LOT_ID,'')::string as AUCTION_EVENT_LOT_ID,
    N.DATA:SELLER_ID::string as SELLER_ID,
    nullif(N.DATA:BUYER_ID,'')::string as BUYER_ID,
    nullif(N.DATA:SCHEME_MATERIAL_TYPE_ID,'')::string as SCHEME_MATERIAL_TYPE_ID,
    nullif(N.DATA:MRF_MATERIAL_TYPE_ID,'')::string as MRF_MATERIAL_TYPE_ID,
    nullif(N.DATA:PICKUP_LOCATION,'')::string as PICKUP_LOCATION,
    nullif(N.DATA:PICKUP_POST_CODE,'')::string as PICKUP_POST_CODE,
    nullif(N.DATA:WEIGHT_IN_TONNES,'')::float as WEIGHT_IN_TONNES,
    nullif(N.DATA:BLOCK_LENGTH_IN_CM,'')::bigint as BLOCK_LENGTH_IN_CM,
    nullif(N.DATA:BLOCK_WIDTH_IN_CM,'')::bigint as BLOCK_WIDTH_IN_CM,
    nullif(N.DATA:BLOCK_DEPTH_IN_CM,'')::bigint as BLOCK_DEPTH_IN_CM,
    nullif(N.DATA:NUMBER_OF_BLOCKS,'')::bigint as NUMBER_OF_BLOCKS,
    nullif(N.DATA:AVAILABLE_FROM,'')::TIMESTAMP_NTZ as AVAILABLE_FROM,
    nullif(N.DATA:SOURCE,'')::string as SOURCE,
    nullif(N.DATA:STATUS,'')::string as STATUS,
    nullif(N.DATA:SALE_PRICE_PER_TONNE,'')::float as SALE_PRICE_PER_TONNE,
    nullif(N.DATA:COMMENTS,'')::string as COMMENTS,
    nullif(N.DATA:COLLECTION_CONSIDERATIONS,'')::string as COLLECTION_CONSIDERATIONS,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    nullif(N.DATA:SOLD_ON,'')::TIMESTAMP_NTZ as SOLD_ON,
    nullif(N.DATA:NOTIFIED,'')::string as NOTIFIED,
    nullif(N.DATA:HAS_ACTUAL_IMAGES,'')::bigint as HAS_ACTUAL_IMAGES,
    nullif(N.DATA:AGREEMENT_DATE,'')::TIMESTAMP_NTZ as AGREEMENT_DATE,
    nullif(N.DATA:RESERVE_PRICE_PER_TONNE,'')::float as RESERVE_PRICE_PER_TONNE,
    nullif(N.DATA:SALE_TERMS,'')::string as SALE_TERMS,
    nullif(N.DATA:DIRECT_SALE_MODE,'')::bigint as DIRECT_SALE_MODE,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:BUYER_USER_ID,'')::string as BUYER_USER_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_SELLER_SITE_ID,'')::bigint as MSC_SELLER_SITE_ID,
    nullif(N.DATA:MSC_BUYER_SITE_ID,'')::bigint as MSC_BUYER_SITE_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N