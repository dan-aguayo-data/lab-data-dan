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
    where lower(FILE_NAME) LIKE lower('%/AG_JIRA_ISSUES/%')
    {% if is_incremental() %}
    and CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Sydney', LANDED_DATETIME)>= (SELECT LATEST_UPDATE_SYD_TIME FROM incremental_date_ref)
    {% else %}
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_JIRA_ISSUES/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    {% endif %}
)

SELECT 
s.value:max_approval_level::float as MAX_APPROVAL_LEVEL,
s.value:approval_level::bigint as APPROVAL_LEVEL,
s.value:type::string as TYPE,
s.value:location_id::bigint as LOCATION_ID,
s.value:related_to::string as RELATED_TO,
s.value:task_workflow_title::string as TASK_WORKFLOW_TITLE,
s.value:action::string as ACTION,
s.value:id::bigint as ID,
s.value:erp_id::string as ERP_ID,
s.value:site_types::string as SITE_TYPES,
s.value:entity_id::bigint as ENTITY_ID,
s.value:create_script_finished::string as CREATE_SCRIPT_FINISHED,
to_timestamp(s.value:date_updated::string, 'MMMM DD YYYY hh24:mi:ss') DATE_UPDATED,
s.value:task_workflow_id::bigint as TASK_WORKFLOW_ID,
s.value:change_status::string as CHANGE_STATUS,
s.value:creator_login::string as CREATOR_LOGIN,
s.value:creator_team::string as CREATOR_TEAM,
s.value:number_of_needed_tasks::float as NUMBER_OF_NEEDED_TASKS,
s.value:scheme_types::string as SCHEME_TYPES,
s.value:summary::string as SUMMARY,
s.value:scheme_participant_types::string as SCHEME_PARTICIPANT_TYPES,
to_timestamp(s.value:date_created::string, 'MMMM DD YYYY hh24:mi:ss') DATE_CREATED,
s.value:status_name::string as STATUS_NAME,
s.value:_1880_full_name::string as _1880_FULL_NAME,
s.value:record_id::bigint as RECORD_ID,
s.value:linked_table::string as LINKED_TABLE,
s.value:legal_entity_name::string as LEGAL_ENTITY_NAME
FROM    source as s