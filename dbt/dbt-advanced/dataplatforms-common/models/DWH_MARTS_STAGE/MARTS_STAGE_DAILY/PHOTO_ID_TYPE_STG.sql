{{
    config(
        materialized = "view",
        enabled = run_flag_dev()
    )
}}

SELECT
    --Natural Key
     PIT.ID
    --Attributes
    ,PIT.MULTI_SCHEME_ID
    ,PIT.NAME
    ,PIT.DISPLAY_ORDER
    ,PIT.EFFECTIVE_FROM AS EFFECTIVE_FROM_DATE
    ,PIT.EFFECTIVE_TO AS EFFECTIVE_TO_DATE    
    --Metadata Attributes
    ,PIT.CREATED_BY
    ,PIT.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,PIT.LAST_MODIFIED_BY
    ,PIT.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME

FROM {{ source('CES_MSCM', 'PHOTO_ID_TYPE') }} AS PIT