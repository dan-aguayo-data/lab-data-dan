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
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM_SEC') }}
    WHERE METADATA:"table-name"='REFUND_PHOTO_ID' AND DATA is not null
)

SELECT
    N.DATA:PHOTO_ID::bigint as PHOTO_ID,
    nullif(N.DATA:PHOTO_ID_TYPE,'')::string as PHOTO_ID_TYPE,
    nullif(N.DATA:PHOTO_ID_NUMBER,'')::string as PHOTO_ID_NUMBER,
    nullif(N.DATA:PHOTO_ID_NAME,'')::string as PHOTO_ID_NAME,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N