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
    where lower(FILE_NAME) LIKE lower('%/AG_EMPLOYEE/%')
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_EMPLOYEE/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

SELECT 
        s.value:_106_sw_description::string as _106_SW_DESCRIPTION,
        s.value:_1576_company_name0::string as _1576_COMPANY_NAME0,
        s.value:_1890_full_name::string as _1890_FULL_NAME,
        s.value:_ldap::string as _LDAP,
        s.value:_login::string as _LOGIN,
        s.value:approval_source::string as APPROVAL_SOURCE,
        s.value:area_code::string as AREA_CODE,
        s.value:assigned_sales_rep::string as ASSIGNED_SALES_REP,
        s.value:buying_stage::string as BUYING_STAGE,
        s.value:cell_phone::string as CELL_PHONE,
        s.value:company_id::string as COMPANY_ID,
        s.value:contact_owner::string as CONTACT_OWNER,
        s.value:country_code::string as COUNTRY_CODE,
        s.value:creator_login::string as CREATOR_LOGIN,
        s.value:creator_name::string as CREATOR_NAME,
        s.value:creator_team::string as CREATOR_TEAM,
        s.value:data_room_access::string as DATA_ROOM_ACCESS,
        s.value:date_created::string as DATE_CREATED,
        s.value:date_updated::string as DATE_UPDATED,
        s.value:deactivate_user::string as DEACTIVATE_USER,
        s.value:deleteable::string as DELETEABLE,
        s.value:demo_data::string as DEMO_DATA,
        s.value:direct_phone::string as DIRECT_PHONE,
        s.value:email::string as EMAIL,
        s.value:first_name::string as FIRST_NAME,
        s.value:full_name::string as FULL_NAME,
        s.value:id::string as ID,
        s.value:last_name::string as LAST_NAME,
        s.value:lead_created_via::string as LEAD_CREATED_VIA,
        s.value:message_description::string as MESSAGE_DESCRIPTION,
        s.value:message_summary::string as MESSAGE_SUMMARY,
        s.value:password::string as PASSWORD,
        s.value:related_to::string as RELATED_TO,
        s.value:rep_phone::string as REP_PHONE,
        s.value:sales_rep_team::string as SALES_REP_TEAM,
        s.value:self_registration_flag::string as SELF_REGISTRATION_FLAG,
        s.value:sso_auth_method::string as SSO_AUTH_METHOD,
        s.value:status::string as STATUS,
        s.value:supported_user::string as SUPPORTED_USER,
        s.value:title::string as TITLE,
        s.value:tracked_fields::string as TRACKED_FIELDS,
        s.value:type::string as TYPE,
        s.value:type_of_contact::string as TYPE_OF_CONTACT,
        s.value:unlinked_company::string as UNLINKED_COMPANY,
        s.value:updater_team::string as UPDATER_TEAM,
        s.value

FROM    source as s