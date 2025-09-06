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
    PU.ID AS ID
    --Attributes
    , PU.MULTI_SCHEME_ID AS MULTI_SCHEME_ID
    , SCHEME.NAME AS SCHEME
    , PU.CRP_ID AS CRP_SITE_NUMBER
    , PS.SITE_NAME AS CRP_SITE_NAME
    , P.PARTICIPANT_NUMBER AS SUPPLIER_NUMBER
    , P.PARTICIPANT_NAME AS SUPPLIER_NAME
    , PU.POS_USER_NAME AS USER_NAME
    , PU.POS_ACCESS AS POS_ACCESS_TYPE
    , PU.STATUS AS STATUS
    , PU.MSC_CRP_SITE_ID
    --Metadata Attributes
    , PU.CREATED_BY AS CREATED_BY
    , PU.CREATED_ON AS CREATED_ON_UTC_DATETIME
    , PU.LAST_MODIFIED_BY AS LAST_MODIFIED_BY
    , PU.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(PU.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')), 
              COALESCE(PS.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')), 
              COALESCE(P.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'POS_USER') }} AS PU
LEFT JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANT_SITES') }} AS PS ON PU.CRP_ID = PS.SITE_NUMBER
LEFT JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANTS') }} AS P ON PS.PARTICIPANT_ID = P.PARTICIPANT_ID
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME ON PU.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}