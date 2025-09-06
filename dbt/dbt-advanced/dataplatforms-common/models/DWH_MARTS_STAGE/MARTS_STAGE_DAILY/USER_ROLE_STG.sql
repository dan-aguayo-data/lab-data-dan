{{
    config(
        materialized = "view",
        enabled = run_flag_dev()
    )
}}

SELECT
    --Natural Key
     ID
    --Attributes
    ,MULTI_SCHEME_ID
    ,USER_ID
    ,ROLE_ID
    --Metadata Attributes
    ,CREATED_BY
    ,CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,LAST_MODIFIED_BY
    ,LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME

FROM {{ source('CES_MSCM', 'USER_ROLE') }}