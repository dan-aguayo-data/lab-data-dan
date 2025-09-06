{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',        
        pre_hook= "{{ incremental_pre() }}",
        post_hook= "{{ incremental_post() }}",
        enabled = run_flag_dev()
    )
}}


SELECT 
    --Natural Key
    USP.ID
    --Foreign Natural Key & Attributes
    ,USP.MULTI_SCHEME_ID
    ,SCHEME.NAME AS SCHEME
    ,USP.MSC_PARTICIPANT_SITE_ID
    ,USP.USER_ID
    ,USP.SCHEME_PARTICIPANT_ID
    --Metadata Attributes
    ,USP.CREATED_BY
    ,USP.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,USP.LAST_MODIFIED_BY
    ,USP.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(USP.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')), 
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
            ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'USER_SCHEME_PARTICIPANT') }} USP
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON USP.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %} 