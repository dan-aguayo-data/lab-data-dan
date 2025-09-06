{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'append',
        enabled = run_flag_exclude_all()
    )
}}


WITH {% if is_incremental() %} incremental_date_ref as (

SELECT LATEST_UPDATE_SYD_TIME 
FROM {{source('CES_REF_DBT','CONTROL_INCREMENTAL_GENERIC')}}
WHERE TABLE_NAME = '{{( model.name )}}' AND PROJECT_NAME = 'RAW'AND ENVIRONMENT = '{{ target.name | upper }}'


),{% endif %} source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where lower(FILE_NAME) LIKE lower('%/AG_DEPARTMENT/%')
    {% if is_incremental() %}
    and CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Sydney', LANDED_DATETIME)>= (SELECT LATEST_UPDATE_SYD_TIME FROM incremental_date_ref)
    {% else %}
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_DEPARTMENT/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    {% endif %}
)

SELECT 
        s.value:_1880_full_name::string as _1880_FULL_NAME,
        s.value:_1888_full_name::string as _1888_FULL_NAME,
        s.value:creator_login::string as CREATOR_LOGIN,
        s.value:creator_team::string as CREATOR_TEAM,
        s.value:date_created::string as DATE_CREATED,
        s.value:date_updated::string as DATE_UPDATED,
        s.value:deleteable::string as DELETEABLE,
        s.value:demo_data::string as DEMO_DATA,
        s.value:department_name::string as DEPARTMENT_NAME,
        s.value:id::string as ID,
        s.value:type::string as TYPE,
        s.value:updater_login::string as UPDATER_LOGIN,
        s.value:updater_team::string as UPDATER_TEAM,
        s.value

FROM    source as s