
{% snapshot crp_pos_device_snap %}
{{
  config(
    unique_key = 'ID',
    strategy   = 'check',
    check_cols = ['ROW_FINGERPRINT'],
    invalidate_hard_deletes = true
  )
}}

with src as (
  select
      ID,
      MULTI_SCHEME_ID,
      SCHEME,
      CRP_SITE_NUMBER,
      CRP_SITE_NAME,
      SUPPLIER_NUMBER,
      SUPPLIER_NAME,
      NAME,
      TYPE,
      STATUS,
      SYNCED,
      CURRENT_VERSION,
      CURRENT_OS_VERSION,
      ENVIRONMENT,
      LATITUDE,
      LONGITUDE,
      LAST_HEARTBEAT_ON,
      LAST_BAG_LABEL_ON,
      LAST_TRANSACTION_ON,
      LAST_DATE,
      POS_FLAG,
      CREATED_ON,
      CREATED_BY,
      CREATED_ON_UTC,
      LAST_MODIFIED_BY,
      LAST_MODIFIED_ON_UTC
  from {{ ref('CRP_POS_DEVICE') }}
),
hashed as (
  select
      s.*,
      {{ dbt_utils.generate_surrogate_key([
          'ID',
          'MULTI_SCHEME_ID',
          'SCHEME',
          'CRP_SITE_NUMBER',
          'CRP_SITE_NAME',
          'SUPPLIER_NUMBER',
          'SUPPLIER_NAME',
          'NAME',
          'TYPE',
          'STATUS',
          'SYNCED',
          'CURRENT_VERSION',
          'CURRENT_OS_VERSION',
          'ENVIRONMENT',
          'LATITUDE',
          'LONGITUDE',
          'LAST_HEARTBEAT_ON',
          'LAST_BAG_LABEL_ON',
          'LAST_TRANSACTION_ON',
          'LAST_DATE',
          'POS_FLAG',
          'CREATED_ON',
          'CREATED_BY',
          'CREATED_ON_UTC',
          'LAST_MODIFIED_BY',
          'LAST_MODIFIED_ON_UTC'
      ]) }} as ROW_FINGERPRINT
  from src s
)

select * from hashed
{% endsnapshot %}
