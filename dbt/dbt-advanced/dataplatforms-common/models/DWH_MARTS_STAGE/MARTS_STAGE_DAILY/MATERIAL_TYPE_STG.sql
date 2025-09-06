{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'MATERIAL_TYPE_ID',        
        pre_hook= "{{ incremental_pre() }}",
        post_hook= "{{ incremental_post() }}",
        enabled = run_flag_dev()
    )
}}

SELECT
    --Natural Key
    MT.ID AS MATERIAL_TYPE_ID
    --Attributes
    , MT.MULTI_SCHEME_ID AS MULTI_SCHEME_ID
    , MT.SCHEME_ID AS SCHEME
    , SCHEME.TIMEZONE
    , MT.NAME AS MATERIAL_TYPE
    , CASE WHEN MT.ID IN ('WA_GLASSAMBER', 'WA_GLASSFLINT', 'WA_GLASSGREEN') THEN 'Glass - Mixed' WHEN MT.ID = 'WA_PETWHITE' THEN 'PET - Colour' ELSE MT.NAME END AS MATERIAL_TYPE_MOD
    , CASE WHEN MT.ID IN ('STEEL', 'WA_STEEL', 'WA_PETWHITE', 'OTHER', 'WA_OTHER', 'HDPE', 'WA_HDPE') THEN 'Other' ELSE MT.NAME END AS MATERIAL_TYPE_LOGISTICS
    , CASE WHEN MT.ID LIKE '%GLASS%' THEN 'Glass' ELSE 'Non Glass' END AS GLASS_FLAG
    , MT.DISPLAY_ORDER AS DISPLAY_ORDER
    , MT.REFUND_ELIGIBLE AS REFUND_ELIGIBLE
    --Metadata Attributes
    , MT.CREATED_BY
    , MT.CREATED_ON AS CREATED_ON_UTC_DATETIME
    , MT.LAST_MODIFIED_BY
    , MT.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME
    , GREATEST(COALESCE(MT.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
               COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS'))
              ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'MATERIAL_TYPE') }} AS MT
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON MT.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %}  