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
    where lower(FILE_NAME) LIKE lower('%/AG_FIELD_CHANGE/%')
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_FIELD_CHANGE/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

SELECT 
    s.value:_1880_full_name::string as _1880_FULL_NAME,
    s.value:_1888_full_name::string as _1888_FULL_NAME,
    s.value:approval_level::string as APPROVAL_LEVEL,
    s.value:column::string as "COLUMN",
    s.value:creator_login::string as CREATOR_LOGIN,
    s.value:creator_team::string as CREATOR_TEAM,
    s.value:date_created::string as DATE_CREATED,
    s.value:date_updated::string as DATE_UPDATED,
    s.value:deleteable::string as DELETEABLE,
    s.value:demo_data::string as DEMO_DATA,
    s.value:entity_id::string as ENTITY_ID,
    s.value:id::string as ID,
    s.value:jira_issue_id::string as JIRA_ISSUE_ID,
    s.value:legal_entity_name::string as LEGAL_ENTITY_NAME,
    s.value:new::string as NEW,
    s.value:old::string as OLD,
    s.value:related_to::string as RELATED_TO,
    s.value:type::string as TYPE,
    s.value:updater_login::string as UPDATER_LOGIN,
    s.value:updater_team::string as UPDATER_TEAM,
    s.value

FROM    source as s