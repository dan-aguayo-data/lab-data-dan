{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID',        
        pre_hook= "{{ incremental_pre() }}",
        post_hook= "{{ incremental_post() }}"
    )
}}

SELECT 
    --Natural Key
     UOM.ID
    --Attributes
    ,UOM.MULTI_SCHEME_ID
    ,UOM.SCHEME_ID AS SCHEME
    ,SCHEME.TIMEZONE
    ,UOM.SCHEME_PARTICIPANT_ID
    ,UOM.MATERIAL_TYPE_ID
    ,MT.NAME AS MATERIAL_TYPE
    ,UOM.FROM_UNIT
    ,UOM.TO_UNIT
    ,UOM.CONVERSION_FACTOR
    ,UOM.EFFECTIVE_FROM AS EFFECTIVE_FROM_DATE
    ,UOM.EFFECTIVE_TO AS EFFECTIVE_TO_DATE
    ,UOM.MSC_PARTICIPANT_SITE_ID
    --Metadata Attributes
    ,UOM.CREATED_BY
    ,UOM.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,UOM.LAST_MODIFIED_BY
    ,UOM.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(UOM.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')), 
              COALESCE(MT.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')), 
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME
    
FROM
{{ source('CES_MSCM', 'UOM_REFERENCE') }} AS UOM
LEFT JOIN {{ source('CES_MSCM', 'MATERIAL_TYPE') }} AS MT
ON UOM.MATERIAL_TYPE_ID = MT.ID
LEFT JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON UOM.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}         