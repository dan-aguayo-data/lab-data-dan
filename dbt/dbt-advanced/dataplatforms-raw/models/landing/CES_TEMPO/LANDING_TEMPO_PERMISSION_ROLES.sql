{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (
    SELECT *
    FROM 
      {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }}
    where lower(FILE_NAME) = 
    (select lower(FILE_NAME) from   {{ source('SNOWPIPE_PROD', 'CES_TEMPO_PROD') }} where lower(FILE_NAME) like lower('PERMISSION_ROLES/%')
    QUALIFY row_number() OVER (PARTITION BY 'PERMISSION_ROLES' ORDER BY LANDED_DATETIME DESC, lower(FILE_NAME) DESC) = 1 )
),   
flatten1 as (

    SELECT VALUE
    FROM LATEST_FILE s,
    lateral flatten(input => s.message:results) f
    
), source_nest1 as (

    select 
    s.VALUE:id::string as ID,
    s.VALUE:accessType::string as ACCESSTYPE,
    s.VALUE:editable::string as EDITABLE,
    s.VALUE:name::string as NAME
  from 
    flatten1 s
  
),
flatten2 as (

    SELECT s.VALUE as VALUE_F1, f.VALUE as VALUE_F2
    FROM flatten1 s,
    lateral flatten(input => s.value:permissions) f
    
), source_nest2 as (

    select 
    s.VALUE_F1:id::string as ID,
    s.VALUE_F2:key::string as PERMISSION_KEY
    from 
    flatten2 s
  
), 
flatten3 as (

    SELECT s.VALUE as VALUE_F1, f.VALUE as VALUE_F2
    FROM flatten1 s,
    lateral flatten(input => s.value:permittedUsers) f
    
), source_nest3 as (

    select 
    s.VALUE_F1:id::string as ID,
    s.VALUE_F2:accountId::string as ACCOUNTID,
    s.VALUE_F2:displayName::string as DISPLAYNAME
    from 
    flatten3 s
  
), final as (

    select source_nest1.*,source_nest2.PERMISSION_KEY, source_nest3.ACCOUNTID,source_nest3.DISPLAYNAME from 
    source_nest1
    inner join 
    source_nest2 on source_nest1.ID = source_nest2.ID
    left join
    source_nest3 on source_nest3.ID = source_nest2.ID
)
select * from final