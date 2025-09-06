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
     HR.ID
    --Attributes
    ,HR.MULTI_SCHEME_ID
    ,HR.SCHEME_ID AS SCHEME
    ,SCHEME_PARTICIPANT_ID
    ,HR.MATERIAL_TYPE_ID
    ,HR.MSC_PARTICIPANT_SITE_ID
    ,MT.NAME AS MATERIAL_TYPE
    ,HR.AMOUNT
    ,TO_DATE(HR.EFFECTIVE_FROM) AS EFFECTIVE_FROM_DATE
    ,TO_CHAR(HR.EFFECTIVE_FROM, 'YYYYMMDD') AS EFFECTIVE_FROM_DATE_ID
    ,TO_DATE(HR.EFFECTIVE_TO) AS EFFECTIVE_TO_DATE
    --Metadata
    ,HR.CREATED_BY
    ,HR.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,HR.LAST_MODIFIED_BY
    ,HR.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(HR.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(MT.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'HANDLING_FEE_REFERENCE') }} AS HR
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON HR.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
LEFT JOIN {{ source('CES_MSCM', 'MATERIAL_TYPE') }} AS MT
ON HR.MATERIAL_TYPE_ID = MT.ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}  