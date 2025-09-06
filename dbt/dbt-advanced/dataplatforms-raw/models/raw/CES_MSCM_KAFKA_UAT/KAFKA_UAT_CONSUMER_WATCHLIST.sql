
{%- set trimmed_source_rel = model.name | replace("KAFKA_UAT_","") -%}
{%- set src_tbl = "CONSUMER_WATCHLIST_S" if is_incremental() else "CONSUMERWATCHLISTEVENT" -%}

{{
    config(
        alias= trimmed_source_rel,
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'CUSTOMER_ID',
        enabled = run_flag_uat()
    )  
}}
  
    WITH source AS (
        SELECT * FROM {{ source('CES_MSCM_KAFKA_UAT', src_tbl|string) }}
    ), WATCHLIST_FLATTEN AS (
        SELECT
             s.RECORD_CONTENT:id::string as KAFKA_ID,
             s.RECORD_CONTENT:data:customerId::string as CUSTOMER_ID,
             s.RECORD_CONTENT:data:customerNumber::string as CUSTOMER_NUMBER,
             s.RECORD_CONTENT:data:markAsDeleted::boolean as MARK_AS_DELETED,
             s.RECORD_CONTENT:data:multiSchemeId::string as MULTI_SCHEME_ID,
             s.RECORD_CONTENT:datetime::TIMESTAMP_NTZ as KAFKA_DATETIME,
             s.RECORD_CONTENT:modifiedBy::string as MODIFIED_BY,
             s.RECORD_CONTENT:source::string as SOURCE,
             s.RECORD_CONTENT:subject::string as SUBJECT,
             s.RECORD_CONTENT:type::string as EVENT_TYPE
        FROM source as s
    ), UAT_DUPLICATE_CATCHER AS(   -- THIS PART IS NOT NEEDED IN PROD, ONLY IN UAT due to data complexities
        SELECT
             MAX(KAFKA_ID) AS KAFKA_ID,
             MAX(KAFKA_DATETIME) AS KAFKA_DATETIME,
             CUSTOMER_ID,
             CUSTOMER_NUMBER,
             MARK_AS_DELETED,
             MULTI_SCHEME_ID,
             MODIFIED_BY,
             SOURCE,
             SUBJECT,
             EVENT_TYPE
             FROM WATCHLIST_FLATTEN
             GROUP BY
             CUSTOMER_ID,
             CUSTOMER_NUMBER,
             MARK_AS_DELETED,
             MULTI_SCHEME_ID,
             MODIFIED_BY,
             SOURCE,
             SUBJECT,
             EVENT_TYPE

    )
    SELECT * FROM UAT_DUPLICATE_CATCHER
    QUALIFY row_number() OVER (PARTITION BY CUSTOMER_ID ORDER BY KAFKA_DATETIME DESC) = 1
