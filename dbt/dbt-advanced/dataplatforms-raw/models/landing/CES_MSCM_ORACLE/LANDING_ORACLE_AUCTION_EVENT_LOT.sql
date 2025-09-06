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
    WHERE METADATA:"table-name"='AUCTION_EVENT_LOT' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:AUCTION_EVENT_ID,'')::string as AUCTION_EVENT_ID,
    nullif(N.DATA:LOT_ITEM_ID,'')::string as LOT_ITEM_ID,
    nullif(N.DATA:CURRENT_BID,'')::string as CURRENT_BID,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:DELETED_BY,'')::string as DELETED_BY,
    nullif(N.DATA:DELETED_ON,'')::TIMESTAMP_NTZ as DELETED_ON,
    N.DATA:VERSION::bigint as VERSION,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N