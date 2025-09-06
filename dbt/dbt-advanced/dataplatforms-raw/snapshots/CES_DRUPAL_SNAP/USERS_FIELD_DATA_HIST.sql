{% snapshot users_field_data_snap %}

    {{
        config(
          strategy='check',
          unique_key='UID',
          check_cols=['LOGIN']
        )
    }}

    select * from {{ source('CES_DRUPAL', 'USERS_FIELD_DATA') }} 

{% endsnapshot %}