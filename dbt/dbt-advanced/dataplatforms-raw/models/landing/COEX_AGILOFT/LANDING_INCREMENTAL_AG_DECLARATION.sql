{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel,
        enabled = run_flag_exclude_all()
    )
}}


WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where lower(FILE_NAME) LIKE lower('%/AG_DECLARATION/%')
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_DECLARATION/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

SELECT 
        s.value:_1880_full_name::string as _1880_FULL_NAME,
        s.value:_1888_full_name::string as _1888_FULL_NAME,
        s.value:additional_notes::string as ADDITIONAL_NOTES,
        s.value:contract_company::string as CONTRACT_COMPANY,
        s.value:contract_id::string as CONTRACT_ID,
        s.value:contract_status::string as CONTRACT_STATUS,
        s.value:contract_type::string as CONTRACT_TYPE,
        s.value:contract_type_applicable_declaration::string as CONTRACT_TYPE_APPLICABLE_DECLARATION,
        s.value:creator_login::string as CREATOR_LOGIN,
        s.value:creator_team::string as CREATOR_TEAM,
        s.value:date_created::string as DATE_CREATED,
        s.value:date_updated::string as DATE_UPDATED,
        s.value:days_in_advance_to_notify_for_due_date::string as DAYS_IN_ADVANCE_TO_NOTIFY_FOR_DUE_DATE,
        s.value:declaration_due_day::string as DECLARATION_DUE_DAY,
        s.value:declaration_due_month::string as DECLARATION_DUE_MONTH,
        s.value:deleteable::string as DELETEABLE,
        s.value:demo_data::string as DEMO_DATA,
        s.value:due_date::string as DUE_DATE,
        s.value:f_2nd_days_in_advance_to_notify_for_due_date::string as F_2ND_DAYS_IN_ADVANCE_TO_NOTIFY_FOR_DUE_DATE,
        s.value:f_2nd_notification_date::string as F_2ND_NOTIFICATION_DATE,
        s.value:id::string as ID,
        s.value:notification_date::string as NOTIFICATION_DATE,
        s.value:requester_email::string as REQUESTER_EMAIL,
        s.value:requester_name::string as REQUESTER_NAME,
        s.value:type::string as TYPE,
        s.value:updater_login::string as UPDATER_LOGIN,
        s.value:wfstate::string as WFSTATE,
        s.value 

FROM    source as s