{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'SCHEME_REF_CODES_ID',        
        pre_hook= "{{ incremental_pre() }}",
        post_hook= "{{ incremental_post() }}",
        enabled = run_flag_dev()
    )
}}

SELECT 
    --Natural Key
     SRC.SCHEME_REF_CODES_ID
    --Attributes
    ,SRC.MULTI_SCHEME_ID
    ,SCHEME.NAME AS SCHEME
    ,SCHEME.TIMEZONE    
    ,SRC.CATEGORY
    ,SRC.CODE
    ,SRC.VALUE
    ,SRC.DESCRIPTION
    ,SRC.EFFECTIVE_FROM AS EFFECTIVE_FROM_DATE
    ,SRC.EFFECTIVE_TO AS EFFECTIVE_TO_DATE
    ,SRC.ROW_EDITING_ENABLED
    ,SRC.ROW_DISPLAY_ENABLED    
    --Metadata Attributes
    ,SRC.CREATED_BY
    ,SRC.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,SRC.LAST_MODIFIED_BY
    ,SRC.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(SRC.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')), 
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'SCHEME_REF_CODES') }} AS SRC
LEFT JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON SRC.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}     