{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel,
        enabled = run_flag_exclude_all()
    )
}}


WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where 
    FILE_NAME=(
      select FILE_NAME from {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
      where lower(FILE_NAME) LIKE lower('%/AG_CONTRACT/%')
      QUALIFY row_number() OVER (PARTITION BY 'AG_CONTRACT' ORDER BY LANDED_DATETIME DESC) = 1
    )
  

    -- SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    -- FROM 
    -- {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    -- where lower(FILE_NAME) LIKE lower('%/AG_CONTRACT/%')
    -- and LANDED_DATETIME>to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')
    
    -- UNION
    
    -- SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, VALUE
    -- FROM
    -- {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }} s,
    -- lateral flatten(input => s.message:result) f
    -- where lower(FILE_NAME) LIKE lower('%/AG_CONTRACT/%')
    -- and LANDED_DATETIME<=to_timestamp('2023-01-08 17:57:03.898','YYYY-MM-DD HH:MI:SS.FF')

)

select 

s.value:alert_color::string as ALERT_COLOR,
s.value:approvals_launched::string as APPROVALS_LAUNCHED,
s.value:asset_involvement::string as ASSET_INVOLVEMENT,
s.value:assigned_team::string as ASSIGNED_TEAM,
s.value:authorised_signer_or_directors::string as AUTHORISED_SIGNER_OR_DIRECTORS,
s.value:city0::string as CITY0,
s.value:company_contact_entry::string as COMPANY_CONTACT_ENTRY,
s.value:company_id::string as COMPANY_ID,
s.value:company_name::string as COMPANY_NAME,
s.value:contract_end_date::string as CONTRACT_END_DATE,
s.value:contract_expiry_date::string as CONTRACT_EXPIRY_DATE,
s.value:contract_party_entry::string as CONTRACT_PARTY_ENTRY,
s.value:contract_review_id::string as CONTRACT_REVIEW_ID,
s.value:contract_review_status::string as CONTRACT_REVIEW_STATUS,
s.value:contract_start_date::string as CONTRACT_START_DATE,
s.value:contract_term_in_months::string as CONTRACT_TERM_IN_MONTHS,
s.value:contract_type::string as CONTRACT_TYPE,
s.value:contract_type_applicable_declaration::string as CONTRACT_TYPE_APPLICABLE_DECLARATION,
s.value:contract_type_id::string as CONTRACT_TYPE_ID,
s.value:contract_type_party_type::string as CONTRACT_TYPE_PARTY_TYPE,
s.value:contract_witness_address::string as CONTRACT_WITNESS_ADDRESS,
s.value:country0::string as COUNTRY0,
s.value:created_by::string as CREATED_BY,
s.value:creator_login::string as CREATOR_LOGIN,
s.value:creator_team::string as CREATOR_TEAM,
s.value:date_created::string as DATE_CREATED,
s.value:date_updated::string as DATE_UPDATED,
s.value:days_in_advance_to_notify_for_renewal::string as DAYS_IN_ADVANCE_TO_NOTIFY_FOR_RENEWAL,
s.value:deed_or_constitution::string as DEED_OR_CONSTITUTION,
s.value:default_print_template_id::string as DEFAULT_PRINT_TEMPLATE_ID,
s.value:deleteable::string as DELETEABLE,
s.value:demo_data::string as DEMO_DATA,
s.value:document_source::string as DOCUMENT_SOURCE,
s.value:f_2nd_internal_signer::string as F_2ND_INTERNAL_SIGNER,
s.value:f_2nd_internal_signer_email::string as F_2ND_INTERNAL_SIGNER_EMAIL,
s.value:f_2nd_internal_signer_id::string as F_2ND_INTERNAL_SIGNER_ID,
s.value:f_2nd_internal_signer_title::string as F_2ND_INTERNAL_SIGNER_TITLE,
s.value:f_4th_party_signer_email::string as F_4TH_PARTY_SIGNER_EMAIL,
s.value:f_4th_party_signer_name::string as F_4TH_PARTY_SIGNER_NAME,
s.value:has_print_template_s_::string as HAS_PRINT_TEMPLATE_S_,
s.value:id::string as ID,
s.value:internal_signer_email::string as INTERNAL_SIGNER_EMAIL,
s.value:internal_signer_full_name::string as INTERNAL_SIGNER_FULL_NAME,
s.value:internal_signer_id::string as INTERNAL_SIGNER_ID,
s.value:internal_signer_title::string as INTERNAL_SIGNER_TITLE,
s.value:is_the_new_contract_a_renewal::string as IS_THE_NEW_CONTRACT_A_RENEWAL,
s.value:latest_attachment_id::string as LATEST_ATTACHMENT_ID,
s.value:latest_attachment_title::string as LATEST_ATTACHMENT_TITLE,
s.value:latest_attachment_type::string as LATEST_ATTACHMENT_TYPE,
s.value:legal_entity_types::string as LEGAL_ENTITY_TYPES,
s.value:location_id::string as LOCATION_ID,
s.value:location_name::string as LOCATION_NAME,
s.value:marked_for_deletion::string as MARKED_FOR_DELETION,
s.value:message_description::string as MESSAGE_DESCRIPTION,
s.value:message_summary::string as MESSAGE_SUMMARY,
s.value:new_company_country::string as NEW_COMPANY_COUNTRY,
s.value:new_company_location_name_for_conversion::string as NEW_COMPANY_LOCATION_NAME_FOR_CONVERSION,
s.value:new_company_primary_role::string as NEW_COMPANY_PRIMARY_ROLE,
s.value:number_of_approvals_needed::string as NUMBER_OF_APPROVALS_NEEDED,
s.value:number_of_approvals_received::string as NUMBER_OF_APPROVALS_RECEIVED,
s.value:number_of_company_signers::string as NUMBER_OF_COMPANY_SIGNERS,
s.value:number_of_ds_files::string as NUMBER_OF_DS_FILES,
s.value:number_of_related_contracts::string as NUMBER_OF_RELATED_CONTRACTS,
s.value:number_of_valid_insurance_certificates::string as NUMBER_OF_VALID_INSURANCE_CERTIFICATES,
s.value:party_main_contact::string as PARTY_MAIN_CONTACT,
s.value:party_main_contact_email::string as PARTY_MAIN_CONTACT_EMAIL,
s.value:party_main_contact_id::string as PARTY_MAIN_CONTACT_ID,
s.value:pb_image_id::string as PB_IMAGE_ID,
s.value:primary_location_id::string as PRIMARY_LOCATION_ID,
s.value:print_template_abbreviation::string as PRINT_TEMPLATE_ABBREVIATION,
s.value:print_template_id::string as PRINT_TEMPLATE_ID,
s.value:print_template_to_generate::string as PRINT_TEMPLATE_TO_GENERATE,
s.value:print_template_version_number::string as PRINT_TEMPLATE_VERSION_NUMBER,
s.value:record_type::string as RECORD_TYPE,
s.value:related_to_for_conversion::string as RELATED_TO_FOR_CONVERSION,
s.value:renewal_contract::string as RENEWAL_CONTRACT,
s.value:renewal_notification_date::string as RENEWAL_NOTIFICATION_DATE,
s.value:renewal_type::string as RENEWAL_TYPE,
s.value:requester_email::string as REQUESTER_EMAIL,
s.value:requester_id::string as REQUESTER_ID,
s.value:requester_name::string as REQUESTER_NAME,
s.value:requester_phone::string as REQUESTER_PHONE,
s.value:requestor_area_code::string as REQUESTOR_AREA_CODE,
s.value:requestor_company_id::string as REQUESTOR_COMPANY_ID,
s.value:requestor_country_code::string as REQUESTOR_COUNTRY_CODE,
s.value:requestor_first_name::string as REQUESTOR_FIRST_NAME,
s.value:requestor_last_name::string as REQUESTOR_LAST_NAME,
s.value:second_term_end_date::string as SECOND_TERM_END_DATE,
s.value:second_term_renewal_notification_date::string as SECOND_TERM_RENEWAL_NOTIFICATION_DATE,
s.value:secure_data_room_access::string as SECURE_DATA_ROOM_ACCESS,
s.value:show_create_approvals_button::string as SHOW_CREATE_APPROVALS_BUTTON,
s.value:signer1_email::string as SIGNER1_EMAIL,
s.value:signer1_full_name::string as SIGNER1_FULL_NAME,
s.value:signer1_title::string as SIGNER1_TITLE,
s.value:small_beverage_manufacturer::string as SMALL_BEVERAGE_MANUFACTURER,
s.value:sole_director::string as SOLE_DIRECTOR,
s.value:state_province::string as STATE_PROVINCE,
s.value:street_address::string as STREET_ADDRESS,
s.value:street_address_2::string as STREET_ADDRESS_2,
s.value:third_term_end_date::string as THIRD_TERM_END_DATE,
s.value:third_term_renewal_notification_date::string as THIRD_TERM_RENEWAL_NOTIFICATION_DATE,
s.value:times_sent_for_approval::string as TIMES_SENT_FOR_APPROVAL,
s.value:type::string as TYPE,
s.value:update_ds_files_to_send_flag::string as UPDATE_DS_FILES_TO_SEND_FLAG,
s.value:updated_by::string as UPDATED_BY,
s.value:updater_login::string as UPDATER_LOGIN,
s.value:updater_team::string as UPDATER_TEAM,
s.value:wfstate::string as WFSTATE,
s.value:zip_or_postal_code0::string as ZIP_OR_POSTAL_CODE0,
s.value 

from source as s