{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'SUPPLIER_NUMBER',
        enabled = run_flag_exclude_all()
    )
}}

WITH source as (

    SELECT FILE_NAME, FILE_ROW_NUMBER, LANDED_DATETIME, MESSAGE as VALUE
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_AGILOFT_CRM') }}
    where lower(FILE_NAME) LIKE lower('%/AGSupplierAdmin%')
    {% if is_incremental() %}
    and to_timestamp(value:date_updated::string, 'MMMM DD YYYY hh24:mi:ss') >= (SELECT dateadd(days, -3, max(DATE_UPDATED)) FROM {{this}})
    {% endif %}
), AG_SUPPLIER_ADMIN_LANDING AS (
select 
  s.value:abn::string as ABN,
  s.value:approval_status::string as APPROVAL_STATUS,
  s.value:business_unit::string as BUSINESS_UNIT,
  s.value:currency_code::string as CURRENCY_CODE,
  s.value:custom_134494957075::string as CUSTOM_134494957075,
  to_timestamp(s.value:date_created::string, 'MMMM DD YYYY hh24:mi:ss') as DATE_CREATED,
  to_timestamp(s.value:date_updated::string, 'MMMM DD YYYY hh24:mi:ss') as DATE_UPDATED,
  s.value:payment_terms_days::bigint as PAYMENT_TERMS_DAYS,
  s.value:registered_for_gst::string as REGISTERED_FOR_GST,
  to_date(s.value:supplier_active_date::string, 'MMMM DD YYYY') as SUPPLIER_ACTIVE_DATE,
  s.value:supplier_admin_address_line_1::string as SUPPLIER_ADMIN_ADDRESS_LINE_1,
  s.value:supplier_admin_bank_account_name::string as SUPPLIER_ADMIN_BANK_ACCOUNT_NAME,
  s.value:supplier_admin_bank_account_number::string as SUPPLIER_ADMIN_BANK_ACCOUNT_NUMBER,
  s.value:supplier_admin_bsb_number::string as SUPPLIER_ADMIN_BSB_NUMBER,
  s.value:supplier_admin_city::string as SUPPLIER_ADMIN_CITY,
  s.value:supplier_admin_contact_email::string as SUPPLIER_CONTACT_EMAIL,
  s.value:supplier_admin_contact_name::string as SUPPLIER_ADMIN_CONTACT_NAME,
  s.value:supplier_admin_country::string as SUPPLIER_ADMIN_COUNTRY,
  s.value:supplier_admin_post_code::string as SUPPLIER_ADMIN_POST_CODE,
  s.value:supplier_admin_remittance_email::string as SUPPLIER_ADMIN_REMITTANCE_EMAIL,
  s.value:supplier_admin_state::string as SUPPLIER_ADMIN_STATE,
  s.value:supplier_contract::string as SUPPLIER_CONTRACT,
  s.value:supplier_legal_entity_name::string as SUPPLIER_LEGAL_ENTITY_NAME,
  s.value:supplier_number::string as SUPPLIER_NUMBER,
  s.value:supplier_type::string as SUPPLIER_TYPE,
  s.value:trading_name::string as TRADING_NAME,
  s.value:type::string as TYPE
  
from source as s
WHERE s.value:supplier_number::string  IS NOT NULL
)
SELECT
    s.*
FROM
    AG_SUPPLIER_ADMIN_LANDING s

QUALIFY row_number() OVER (PARTITION BY s.SUPPLIER_NUMBER ORDER BY s.DATE_UPDATED DESC) = 1