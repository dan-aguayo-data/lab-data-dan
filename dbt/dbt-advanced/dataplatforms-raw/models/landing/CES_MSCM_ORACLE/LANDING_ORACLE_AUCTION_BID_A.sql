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
    WHERE METADATA:"table-name"='AUCTION_BID_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:AUCTION_EVENT_LOT_ID,'')::string as AUCTION_EVENT_LOT_ID,
    nullif(N.DATA:BIDDER,'')::string as BIDDER,
    nullif(N.DATA:BID_PRICE_PER_TONNE,'')::float as BID_PRICE_PER_TONNE,
    nullif(N.DATA:SUBMITTED_ON,'')::TIMESTAMP_NTZ as SUBMITTED_ON,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:AUCTION_PROXY_BID_ID,'')::bigint as AUCTION_PROXY_BID_ID,
    nullif(N.DATA:CANCELLED_BY,'')::string as CANCELLED_BY,
    nullif(N.DATA:CANCELLED_ON,'')::TIMESTAMP_NTZ as CANCELLED_ON,
    nullif(N.DATA:MSC_BIDDER_SITE_ID,'')::bigint as MSC_BIDDER_SITE_ID,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N