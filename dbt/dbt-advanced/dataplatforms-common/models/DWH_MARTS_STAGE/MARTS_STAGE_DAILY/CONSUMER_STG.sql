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
    C.SCHEME_PARTICIPANT_ID as ID
    --Foreign Natural Key
    ,C.BANK_ACCOUNT_ID
    ,C.MULTI_SCHEME_ID
    --Attributes
    ,SCHEME.NAME AS SCHEME
    ,C.CONTACT_FIRST_NAME
    ,C.CONTACT_LAST_NAME
    ,C.CONTACT_EMAIL
    ,C.COMPANY_EMAIL
    ,C.INDIVIDUAL_CONSUMER
    ,C.CHARITY_REGISTRATION_NUMBER
    ,C.GST_REGISTERED
    ,C.GST_CONCESSION
    ,C.IS_COMMUNITY_GROUP
    ,C.GENDER
    ,C.AGE_BRACKET
    ,C.AGE_CONFIRMATION
    ,C.TERMS_AND_CONDITIONS_ACCEPTED
    ,C.SYNCED
    ,C.CHARITY
    --Metadata Attributes
    ,C.CREATED_BY
    ,C.CREATED_ON AS CREATED_ON_UTC_DATETIME
    ,C.LAST_MODIFIED_BY
    ,C.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC_DATETIME  
    ,GREATEST(COALESCE(C.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')),
              COALESCE(SCHEME.LAST_MODIFIED_ON,to_timestamp('1900-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')) 
             ) AS INCREMENTAL_UTC_DATETIME

FROM {{ source('CES_MSCM', 'CONSUMER') }} AS C
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON C.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID
{% if is_incremental() %}
WHERE INCREMENTAL_UTC_DATETIME >= (SELECT dateadd(hours, {{var('general_delta_load_hours')}}, max(LATEST_UPDATE_UTC_TIME)) FROM  CES_REF.CES_DBT.DBT_INCREMENTAL_LOG_CONTROL WHERE TABLE_NAME = '{{model.name}}' )
{% endif %} 