{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'CONTRACT_ID',        
        pre_hook= "{{ incremental_pre() }}",
        post_hook= "{{ incremental_post() }}",
        enabled = run_flag_dev()
    )
}}

SELECT
    --Natural Key
     SC.CONTRACT_ID
    --Attrubutes
    ,SC.CONTRACT_ORGANIZATION_ID
    ,SC.MULTI_SCHEME_ID
    ,SCHEME.NAME AS SCHEME
    ,SCHEME.TIMEZONE    
    ,SC.PARTICIPANT_ID
    ,P.PARTICIPANT_NUMBER
    ,P.PARTICIPANT_NAME    
    ,SC.CRM_CONTRACT_DOC_ID
    ,SC.CONTRACT_NUMBER
    ,SC.DOCUMENT_TYPE
    ,SC.STATUS
    ,SC.EFFECTIVE_START_DATE
    ,SC.EFFECTIVE_END_DATE
    ,SC.CMS_LAST_UPDATED AS CMS_LAST_UPDATED_DATE
    --Metadata Attributes
    ,SC.CREATED_BY
    ,SC.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,SC.LAST_MODIFIED_BY
    ,SC.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(SC.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(P.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME
FROM
{{ source('CES_MSCM', 'MDT_SCHEME_CONTRACTS') }} AS SC
LEFT JOIN {{ source('CES_MSCM', 'MDT_PARTICIPANTS') }} AS P
ON SC.PARTICIPANT_ID = P.PARTICIPANT_ID
LEFT JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON SC.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}  