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
    where lower(FILE_NAME) LIKE lower('%/AG_ENTITY/%')
    {% if is_incremental() %}
    and CONVERT_TIMEZONE('America/Los_Angeles', 'Australia/Sydney', LANDED_DATETIME)>= (SELECT LATEST_UPDATE_SYD_TIME FROM incremental_date_ref)
    {% else %}
    and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    UNION
    
    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    FROM
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    lateral flatten(input => s.message:result) f
    where lower(FILE_NAME) LIKE lower('%/AG_ENTITY/%')
    and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    {% endif %}
), AG_ENTITY_HISTORY_LANDING AS (

SELECT s.value:_1792_full_name::string as _1792_FULL_NAME,
s.value:_1794_full_name::string as _1794_FULL_NAME,
s.value:abn::string as ABN,
s.value:add_or_update_physical_address::string as ADD_OR_UPDATE_PHYSICAL_ADDRESS,
s.value:add_or_update_registered_office_address::string as ADD_OR_UPDATE_REGISTERED_OFFICE_ADDRESS,
s.value:bank_account_name::string as BANK_ACCOUNT_NAME,
s.value:bank_account_number::string as BANK_ACCOUNT_NUMBER,
s.value:bank_branch::string as BANK_BRANCH,
s.value:bsb::string as BSB,
s.value:business_address_location_name::string as BUSINESS_ADDRESS_LOCATION_NAME,
s.value:business_email_address::string as BUSINESS_EMAIL_ADDRESS,
s.value:business_location_area_code::string as BUSINESS_LOCATION_AREA_CODE,
s.value:business_location_country_code::string as BUSINESS_LOCATION_COUNTRY_CODE,
s.value:business_phone_number::string as BUSINESS_PHONE_NUMBER,
s.value:business_unit_name_trading_name::string as BUSINESS_UNIT_NAME_TRADING_NAME,
s.value:c::string as C,
s.value:company_name::string as COMPANY_NAME,
s.value:company_number::string as COMPANY_NUMBER,
s.value:contract_attachments_count::string as CONTRACT_ATTACHMENTS_COUNT,
s.value:contract_is_for::string as CONTRACT_IS_FOR,
s.value:contract_owner_email::string as CONTRACT_OWNER_EMAIL,
s.value:contract_owner_id::string as CONTRACT_OWNER_ID,
s.value:contract_status::string as CONTRACT_STATUS,
s.value:creator_login::string as CREATOR_LOGIN,
s.value:creator_name::string as CREATOR_NAME,
s.value:creator_team::string as CREATOR_TEAM,
s.value:currency::string as CURRENCY,
to_timestamp(s.value:date_created::string, 'MON DD YYYY HH:MI:SS') as DATE_CREATED,
to_timestamp(s.value:date_updated::string, 'MON DD YYYY HH:MI:SS') as DATE_UPDATED,
s.value:deleteable::string as DELETEABLE,
s.value:demo_data::string as DEMO_DATA,
s.value:erp_id::string as ERP_ID,
s.value:flag_field::string as FLAG_FIELD,
s.value:gst_applicable::string as GST_APPLICABLE,
s.value:id::string as ID,
s.value:initial_user_email::string as INITIAL_USER_EMAIL,
s.value:initial_user_id::string as INITIAL_USER_ID,
s.value:initial_user_name::string as INITIAL_USER_NAME,
s.value:insurance_certificate_owner::string as INSURANCE_CERTIFICATE_OWNER,
s.value:insurance_certificate_owner_id::string as INSURANCE_CERTIFICATE_OWNER_ID,
s.value:internal_contract_owner::string as INTERNAL_CONTRACT_OWNER,
s.value:latest_contract_end_date::string as LATEST_CONTRACT_END_DATE,
s.value:latest_contract_id::string as LATEST_CONTRACT_ID,
s.value:latest_contract_status::string as LATEST_CONTRACT_STATUS,
s.value:legal_entity_types::string as LEGAL_ENTITY_TYPES,
s.value:location_entity_unique_key::string as LOCATION_ENTITY_UNIQUE_KEY,
s.value:location_physical_address_flag::string as LOCATION_PHYSICAL_ADDRESS_FLAG,
s.value:location_registered_office_flag::string as LOCATION_REGISTERED_OFFICE_FLAG,
s.value:main_city::string as MAIN_CITY,
s.value:main_country::string as MAIN_COUNTRY,
s.value:main_location_id::string as MAIN_LOCATION_ID,
s.value:main_location_name::string as MAIN_LOCATION_NAME,
s.value:main_state_province::string as MAIN_STATE_PROVINCE,
s.value:main_street_address::string as MAIN_STREET_ADDRESS,
s.value:main_zip_or_postal_code::string as MAIN_ZIP_OR_POSTAL_CODE,
s.value:message_description::string as MESSAGE_DESCRIPTION,
s.value:message_id::string as MESSAGE_ID,
s.value:message_summary::string as MESSAGE_SUMMARY,
s.value:number_of_active_insurance_certificates::string as NUMBER_OF_ACTIVE_INSURANCE_CERTIFICATES,
s.value:oracle_manufacturer_id::string as ORACLE_MANUFACTURER_ID,
to_date(s.value:original_start_date::string, 'MMMM DD YYYY') as ORIGINAL_START_DATE,
s.value:owner_login::string as OWNER_LOGIN,
s.value:physical_location::string as PHYSICAL_LOCATION,
s.value:physical_location_city::string as PHYSICAL_LOCATION_CITY,
s.value:physical_location_country::string as PHYSICAL_LOCATION_COUNTRY,
s.value:physical_location_id::string as PHYSICAL_LOCATION_ID,
s.value:physical_location_location_entity_unique_key::string as PHYSICAL_LOCATION_LOCATION_ENTITY_UNIQUE_KEY,
s.value:physical_location_state_province::string as PHYSICAL_LOCATION_STATE_PROVINCE,
s.value:physical_location_zip_or_postal_code::string as PHYSICAL_LOCATION_ZIP_OR_POSTAL_CODE,
s.value:physical_street_address_1::string as PHYSICAL_STREET_ADDRESS_1,
s.value:record_ownership::string as RECORD_OWNERSHIP,
s.value:registered_office::string as REGISTERED_OFFICE,
s.value:registered_office_city::string as REGISTERED_OFFICE_CITY,
s.value:registered_office_country::string as REGISTERED_OFFICE_COUNTRY,
s.value:registered_office_email_address::string as REGISTERED_OFFICE_EMAIL_ADDRESS,
s.value:registered_office_location_id::string as REGISTERED_OFFICE_LOCATION_ID,
s.value:registered_office_location_name::string as REGISTERED_OFFICE_LOCATION_NAME,
s.value:registered_office_state_province::string as REGISTERED_OFFICE_STATE_PROVINCE,
s.value:registered_office_street_address_1::string as REGISTERED_OFFICE_STREET_ADDRESS_1,
s.value:registered_office_street_address_2::string as REGISTERED_OFFICE_STREET_ADDRESS_2,
s.value:registered_office_zip_or_postal_code::string as REGISTERED_OFFICE_ZIP_OR_POSTAL_CODE,
s.value:remittance_email_address::string as REMITTANCE_EMAIL_ADDRESS,
s.value:renewal_number::string as RENEWAL_NUMBER,
s.value:secure_data_room_access::string as SECURE_DATA_ROOM_ACCESS,
s.value:small_beverage_manufacturer::string as SMALL_BEVERAGE_MANUFACTURER,
s.value:sole_director::string as SOLE_DIRECTOR,
to_date(s.value:start_date::string, 'MMMM DD YYYY') as START_DATE,
s.value:status::string as STATUS,
s.value:supplier_arrangement_number::string as SUPPLIER_ARRANGEMENT_NUMBER,
s.value:supplier_arrangement_registered_in_nsw::string as SUPPLIER_ARRANGEMENT_REGISTERED_IN_NSW,
s.value:tracked_fields::string as TRACKED_FIELDS,
s.value:type::string as TYPE,
s.value:type_of_support::string as TYPE_OF_SUPPORT,
s.value:use_as_reference::string as USE_AS_REFERENCE,
s.value:wfstate::string as WFSTATE,
array_to_string(parse_json(s.value:scheme_participant_type), ', ') as SCHEME_PARTICIPANT_TYPE,
s.value:custom_134494929880::string as CUSTOM_134494929880,
s.value:custom_134494242937::string as CUSTOM_134494242937,
s.value:small_beverage_manufacturer::string as SMALL_BM,
s.value

FROM    source as s
)
SELECT distinct
 _1792_FULL_NAME
,_1794_FULL_NAME
,ABN
,ADD_OR_UPDATE_PHYSICAL_ADDRESS
,ADD_OR_UPDATE_REGISTERED_OFFICE_ADDRESS
,BANK_ACCOUNT_NAME
,BANK_ACCOUNT_NUMBER
,BANK_BRANCH
,BSB
,BUSINESS_ADDRESS_LOCATION_NAME
,BUSINESS_EMAIL_ADDRESS
,BUSINESS_LOCATION_AREA_CODE
,BUSINESS_LOCATION_COUNTRY_CODE
,BUSINESS_PHONE_NUMBER
,BUSINESS_UNIT_NAME_TRADING_NAME
,C
,COMPANY_NAME
,COMPANY_NUMBER
,CONTRACT_ATTACHMENTS_COUNT
,CONTRACT_IS_FOR
,CONTRACT_OWNER_EMAIL
,CONTRACT_OWNER_ID
,CONTRACT_STATUS
,CREATOR_LOGIN
,CREATOR_NAME
,CREATOR_TEAM
,CURRENCY
,DATE_CREATED
,DATE_UPDATED
,DELETEABLE
,DEMO_DATA
,ERP_ID
,FLAG_FIELD
,GST_APPLICABLE
,ID
,INITIAL_USER_EMAIL
,INITIAL_USER_ID
,INITIAL_USER_NAME
,INSURANCE_CERTIFICATE_OWNER
,INSURANCE_CERTIFICATE_OWNER_ID
,INTERNAL_CONTRACT_OWNER
,LATEST_CONTRACT_END_DATE
,LATEST_CONTRACT_ID
,LATEST_CONTRACT_STATUS
,LEGAL_ENTITY_TYPES
,LOCATION_ENTITY_UNIQUE_KEY
,LOCATION_PHYSICAL_ADDRESS_FLAG
,LOCATION_REGISTERED_OFFICE_FLAG
,MAIN_CITY
,MAIN_COUNTRY
,MAIN_LOCATION_ID
,MAIN_LOCATION_NAME
,MAIN_STATE_PROVINCE
,MAIN_STREET_ADDRESS
,MAIN_ZIP_OR_POSTAL_CODE
,MESSAGE_DESCRIPTION
,MESSAGE_ID
,MESSAGE_SUMMARY
,NUMBER_OF_ACTIVE_INSURANCE_CERTIFICATES
,ORACLE_MANUFACTURER_ID
,ORIGINAL_START_DATE
,OWNER_LOGIN
,PHYSICAL_LOCATION
,PHYSICAL_LOCATION_CITY
,PHYSICAL_LOCATION_COUNTRY
,PHYSICAL_LOCATION_ID
,PHYSICAL_LOCATION_LOCATION_ENTITY_UNIQUE_KEY
,PHYSICAL_LOCATION_STATE_PROVINCE
,PHYSICAL_LOCATION_ZIP_OR_POSTAL_CODE
,PHYSICAL_STREET_ADDRESS_1
,RECORD_OWNERSHIP
,REGISTERED_OFFICE
,REGISTERED_OFFICE_CITY
,REGISTERED_OFFICE_COUNTRY
,REGISTERED_OFFICE_EMAIL_ADDRESS
,REGISTERED_OFFICE_LOCATION_ID
,REGISTERED_OFFICE_LOCATION_NAME
,REGISTERED_OFFICE_STATE_PROVINCE
,REGISTERED_OFFICE_STREET_ADDRESS_1
,REGISTERED_OFFICE_STREET_ADDRESS_2
,REGISTERED_OFFICE_ZIP_OR_POSTAL_CODE
,REMITTANCE_EMAIL_ADDRESS
,RENEWAL_NUMBER
,SECURE_DATA_ROOM_ACCESS
,SMALL_BEVERAGE_MANUFACTURER
,SOLE_DIRECTOR
,START_DATE
,STATUS
,SUPPLIER_ARRANGEMENT_NUMBER
,SUPPLIER_ARRANGEMENT_REGISTERED_IN_NSW
,TRACKED_FIELDS
,TYPE
,TYPE_OF_SUPPORT
,USE_AS_REFERENCE
,WFSTATE
,SCHEME_PARTICIPANT_TYPE
,CUSTOM_134494929880
,CUSTOM_134494242937
,SMALL_BM
FROM AG_ENTITY_HISTORY_LANDING