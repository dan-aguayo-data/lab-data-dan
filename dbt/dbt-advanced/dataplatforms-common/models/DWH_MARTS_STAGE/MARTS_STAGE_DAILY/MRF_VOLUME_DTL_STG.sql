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
     DTL.MRF_VOLUME_DTL_ID AS ID
    --Foreign Natural Key
    ,DTL.TRANSACTION_LINE_ID
    ,DTL.MRF_VOLUME_HDR_ID
    ,DTL.MATERIAL_TYPE_ID
    ,DTL.MRF_MATERIAL_TYPE_ID
    ,DTL.MULTI_SCHEME_ID
    --Attributes
    ,SCHEME.NAME AS SCHEME 
    ,DTL.UNITS
    ,DTL.KILOS
    --Metadata Attributes
    ,DTL.CREATED_BY AS CREATED_BY
    ,DTL.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,DTL.LAST_MODIFIED_BY AS LAST_MODIFIED_BY
    ,DTL.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    ,GREATEST(COALESCE(DTL.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'MRF_VOLUME_DTL') }} AS DTL
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON DTL.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}  