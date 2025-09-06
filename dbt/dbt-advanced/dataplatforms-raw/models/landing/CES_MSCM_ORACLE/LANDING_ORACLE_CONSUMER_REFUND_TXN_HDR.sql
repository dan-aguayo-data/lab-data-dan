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
    WHERE METADATA:"table-name"='CONSUMER_REFUND_TXN_HDR' AND DATA is not null
)

SELECT
    N.DATA:ID::string as ID,
    nullif(N.DATA:POS_DEVICE_ID,'')::string as POS_DEVICE_ID,
    N.DATA:CONSUMER_ID::string as CONSUMER_ID,
    nullif(N.DATA:PHOTO_ID_TYPE,'')::string as PHOTO_ID_TYPE,
    nullif(N.DATA:PHOTO_ID_NUMBER,'')::string as PHOTO_ID_NUMBER,
    N.DATA:PAYMENT_METHOD::string as PAYMENT_METHOD,
    nullif(N.DATA:CUSTOMER_DECLARATION,'')::bigint as CUSTOMER_DECLARATION,
    nullif(N.DATA:BAG_LABEL_ID,'')::string as BAG_LABEL_ID,
    nullif(N.DATA:BAG_ISSUE_TYPE,'')::string as BAG_ISSUE_TYPE,
    N.DATA:STATUS::string as STATUS,
    N.DATA:TRANSACTED_ON::TIMESTAMP_NTZ as TRANSACTED_ON,
    nullif(N.DATA:TRANSACTED_BY,'')::string as TRANSACTED_BY,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:NOTIFIED,'')::string as NOTIFIED,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:MSC_CONSUMER_SITE_ID,'')::bigint as MSC_CONSUMER_SITE_ID,
    nullif(N.DATA:PHYSICAL_CONTAINER_RETURN_POINT,'')::string as PHYSICAL_CONTAINER_RETURN_POINT,
    nullif(N.DATA:REFUND_CRP,'')::string as REFUND_CRP,
    nullif(N.DATA:PHOTO_ID_NAME,'')::string as PHOTO_ID_NAME,
    nullif(N.DATA:CONSUMER_ALIAS,'')::string as CONSUMER_ALIAS,
    nullif(N.DATA:RECIPIENT_ALIAS,'')::string as RECIPIENT_ALIAS,
    nullif(N.DATA:RECIPIENT_CONSUMER_ID,'')::string as RECIPIENT_CONSUMER_ID,
    nullif(N.DATA:MSC_RECIPIENT_SITE_ID,'')::bigint as MSC_RECIPIENT_SITE_ID,
    nullif(N.DATA:PHOTO_ID,'')::bigint as PHOTO_ID,
    nullif(N.DATA:BAG_ISSUE_DESC,'')::string as BAG_ISSUE_DESC,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N