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
    where lower(FILE_NAME) LIKE lower('%/AG_CONTRACT_TYPE/%')
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_CONTRACT_TYPE/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

SELECT 
        s.value:_1880_full_name::string as _1880_FULL_NAME,
        s.value:_1888_full_name::string as _1888_FULL_NAME,
        s.value:contract_or_declaration::string as CONTRACT_OR_DECLARATION,
        s.value:contract_type::string as CONTRACT_TYPE,
        s.value:creator_login::string as CREATOR_LOGIN,
        s.value:creator_team::string as CREATOR_TEAM,
        s.value:date_created::string as DATE_CREATED,
        s.value:date_updated::string as DATE_UPDATED,
        s.value:declaration_due_day::string as DECLARATION_DUE_DAY,
        s.value:default_print_template_id::string as DEFAULT_PRINT_TEMPLATE_ID,
        s.value:deleteable::string as DELETEABLE,
        s.value:demo_data::string as DEMO_DATA,
        s.value:description::string as DESCRIPTION,
        s.value:first_term_period::string as FIRST_TERM_PERIOD,
        s.value:has_print_template::string as HAS_PRINT_TEMPLATE,
        s.value:id::string as ID,
        s.value:internal_use_only::string as INTERNAL_USE_ONLY,
        s.value:party_type::string as PARTY_TYPE,
        s.value:print_template_title::string as PRINT_TEMPLATE_TITLE,
        s.value:second_term_period::string as SECOND_TERM_PERIOD,
        s.value:status::string as STATUS,
        s.value:third_term_period::string as THIRD_TERM_PERIOD,
        s.value:type::string as TYPE,
        s.value:updater_login::string as UPDATER_LOGIN,
        s.value:updater_team::string as UPDATER_TEAM,
        s.value 

FROM    source as s