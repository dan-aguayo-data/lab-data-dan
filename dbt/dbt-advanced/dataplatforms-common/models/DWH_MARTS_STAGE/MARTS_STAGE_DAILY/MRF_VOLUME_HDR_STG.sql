
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
    HDR.MRF_VOLUME_HDR_ID AS ID
    --Foreign Natural Key
    ,HDR.MRF_ID
    ,HDR.MSC_PARTICIPANT_SITE_ID
    ,HDR.VENDOR_ID
    ,HDR.TRANSACTION_ID
    ,HDR.MULTI_SCHEME_ID
    --Attributes
    ,SCHEME.NAME AS SCHEME
    ,HDR.STATUS
    ,HDR.SUBMITTED_BY
    ,HDR.SUBMITTED_ON AS SUBMITTED_ON_LOCAL_DATETIME
    ,HDR.TRANSACTED_BY
    ,HDR.TRANSACTED_ON AS TRANSACTED_ON_LOCAL_DATETIME
    ,HDR.ENTRY_TYPE
    ,HDR.PERIOD
    ,HDR.PERIOD_TYPE
    ,HDR.TOTAL_UNITS
    ,HDR.TOTAL_KILOS
    ,HDR.ATTRIBUTE1
    ,HDR.ATTRIBUTE2
    ,HDR.ATTRIBUTE3
    ,HDR.ATTRIBUTE4
    ,HDR.ATTRIBUTE5
    --Metadata Attributes
    ,HDR.CREATED_BY AS CREATED_BY
    ,HDR.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,HDR.LAST_MODIFIED_BY AS LAST_MODIFIED_BY
    ,HDR.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME 
    ,GREATEST(COALESCE(HDR.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
             ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'MRF_VOLUME_HDR') }} AS HDR 
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON HDR.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}  