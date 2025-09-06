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
    where lower(FILE_NAME) LIKE lower('%/AG_LOCATION/%')
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_LOCATION/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

SELECT 
s.value:_1880_full_name::string as _1880_FULL_NAME,
s.value:_1888_full_name::string as _1888_FULL_NAME,
to_date(s.value:active_date::string, 'MMMM DD YYYY') as ACTIVE_DATE,
s.value:aus_state::string as AUS_STATE,
s.value:business_type::string as BUSINESS_TYPE,
s.value:city::string as CITY,
s.value:closed_public_holidays::string as CLOSED_PUBLIC_HOLIDAYS,
s.value:company_id::string as COMPANY_ID,
s.value:company_location::string as COMPANY_LOCATION,
s.value:company_name::string as COMPANY_NAME,
s.value:country::string as COUNTRY,
s.value:creator_login::string as CREATOR_LOGIN,
s.value:creator_team::string as CREATOR_TEAM,
to_timestamp(s.value:date_created::string, 'MMMM DD YYYY hh24:mi:ss') as DATE_CREATED,
to_timestamp(s.value:date_updated::string, 'MMMM DD YYYY hh24:mi:ss') as DATE_UPDATED,
s.value:deleteable::string as DELETEABLE,
s.value:demo_data::string as DEMO_DATA,
s.value:electorate::string as ELECTORATE,
s.value:email_address::string as EMAIL_ADDRESS,
s.value:friday_closed::string as FRIDAY_CLOSED,
s.value:id::string as ID,
s.value:local_council::string as LOCAL_COUNCIL,
s.value:location_entity_unique_key::string as LOCATION_ENTITY_UNIQUE_KEY,
s.value:location_name::string as LOCATION_NAME,
s.value:logistics_services_provider::string as LOGISTICS_SERVICES_PROVIDER,
s.value:mobile_number::string as MOBILE_NUMBER,
to_date(s.value:mobilisation_completion_date::string, 'MMMM DD YYYY') as MOBILISATION_COMPLETION_DATE,
s.value:monday_closed::string as MONDAY_CLOSED,
s.value:open_24_hours::string as OPEN_24_HOURS,
s.value:processor_supplier_site_name::string as PROCESSOR_SUPPLIER_SITE_NAME,
s.value:record_ownership::string as RECORD_OWNERSHIP,
s.value:region::string as REGION,
s.value:regional_manager::string as REGIONAL_MANAGER,
s.value:regional_manager_email::string as REGIONAL_MANAGER_EMAIL,
s.value:regional_manager_id::string as REGIONAL_MANAGER_ID,
s.value:responsible_par::string as RESPONSIBLE_PAR,
s.value:saturday_closed::string as SATURDAY_CLOSED,
s.value:scheme_site_id::string as SCHEME_SITE_ID,
s.value:previous_scheme_id::string as PREVIOUS_SCHEME_ID,
s.value:site_contact_name::string as SITE_CONTACT_NAME,
s.value:site_status::string as SITE_STATUS,
s.value:state_province::string as STATE_PROVINCE,
s.value:street_address::string as STREET_ADDRESS,
s.value:sunday_closed::string as SUNDAY_CLOSED,
s.value:telephone::string as TELEPHONE,
s.value:thursday_closed::string as THURSDAY_CLOSED,
s.value:tracked_fields::string as TRACKED_FIELDS,
s.value:tuesday_closed::string as TUESDAY_CLOSED,
s.value:type::string as TYPE,
s.value:updater_login::string as UPDATER_LOGIN,
s.value:updater_team::string as UPDATER_TEAM,
s.value:website_email_address::string as WEBSITE_EMAIL_ADDRESS,
s.value:wednesday_closed::string as WEDNESDAY_CLOSED,
s.value:x_coord::string as X_COORD,
s.value:y_coord::string as Y_COORD,
s.value:zip_or_postal_code::string as ZIP_OR_POSTAL_CODE,
array_to_string(parse_json(s.value:crp_type), ', ') as crp_type,
array_to_string(parse_json(s.value:location_type), ', ') as location_type,
array_to_string(parse_json(s.value:payment_type0), ', ') as payment_type0,
array_to_string(parse_json(s.value:crp_site_operations), ', ') as crp_site_operations,
s.value:friday_close_time::string as friday_close_time,
s.value:friday_open_time::string as friday_open_time,
s.value:monday_close_time::string as monday_close_time,
s.value:monday_open_time::string as monday_open_time,
s.value:saturday_close_time::string as saturday_close_time,
s.value:saturday_open_time::string as saturday_open_time,
s.value:sunday_close_time::string as sunday_close_time,
s.value:sunday_open_time::string as sunday_open_time,
s.value:thursday_close_time::string as thursday_close_time,
s.value:thursday_open_time::string as thursday_open_time,
s.value:tuesday_close_time::string as tuesday_close_time,
s.value:tuesday_open::string as tuesday_open,
s.value:wednesday_close_time::string as wednesday_close_time,
s.value:wednesday_open_time::string as wednesday_open_time,
s.value:special_trading_hours::string as special_trading_hours,
to_date(nullif(s.value:inactive_date::string,''), 'MMMM DD YYYY') as inactive_date,
s.value

FROM    source as s