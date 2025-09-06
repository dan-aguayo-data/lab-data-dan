{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}
 
/*
WITH LATEST_FILE as (
  SELECT *
  FROM
  {{ source('SNOWPIPE_PROD', 'CES_GREAT_EXPECTATIONS_PROD') }}
  WHERE
    FILE_NAME in (
      SELECT FILE_NAME FROM (
        SELECT FILE_NAME FROM {{ source('SNOWPIPE_PROD', 'CES_GREAT_EXPECTATIONS_PROD') }}
        WHERE lower(FILE_NAME) LIKE lower('validations/%')
        QUALIFY row_number() OVER (PARTITION BY CONCAT(split_part(FILE_NAME, '/', 2),split_part(FILE_NAME, '/', 3)) ORDER BY LANDED_DATETIME DESC) = 1)
    )
),
source as (
  SELECT *
  FROM LATEST_FILE s,
  lateral flatten(input => s.message:results) f  
)

*/

WITH source as (
  
  SELECT *
  FROM {{ source('SNOWPIPE_PROD', 'CES_GREAT_EXPECTATIONS_PROD') }}
   s,
  lateral flatten(input => s.message:results) f 
  WHERE lower(FILE_NAME) LIKE lower('validations/%')

),
puil as (
  
  SELECT f.file_name,
  replace(g.value:CHECKPOINT_VALUE::string, 'null', '"null"') as CHECKPOINT_VALUE,
  replace(g.value:CHECKPOINT_PRIMARY_KEY::string, 'null', '"null"') as CHECKPOINT_PRIMARY_KEY
  FROM source f,
  lateral flatten(input => f.value:result:partial_unexpected_index_list) g 
  
),
puil_listagg as (

  select 
  file_name, 
  listagg(CHECKPOINT_VALUE, ', ') WITHIN GROUP (ORDER BY CHECKPOINT_VALUE) partial_unexpected_index_list_value,
  listagg(CHECKPOINT_PRIMARY_KEY, ', ') WITHIN GROUP (ORDER BY CHECKPOINT_PRIMARY_KEY) partial_unexpected_index_list_pk
  from puil
  group by file_name
  
),
uil as (
  
  SELECT f.file_name,
  replace(g.value:CHECKPOINT_VALUE::string, 'null', '"null"') as CHECKPOINT_VALUE,
  replace(g.value:CHECKPOINT_PRIMARY_KEY::string, 'null', '"null"') as CHECKPOINT_PRIMARY_KEY
  FROM source f,
  lateral flatten(input => f.value:result:unexpected_index_list) g 
  
),
uil_listagg as (

  select 
  file_name, 
  listagg(CHECKPOINT_VALUE, ', ') WITHIN GROUP (ORDER BY CHECKPOINT_VALUE) unexpected_index_list_value,
  listagg(CHECKPOINT_PRIMARY_KEY, ', ') WITHIN GROUP (ORDER BY CHECKPOINT_PRIMARY_KEY) unexpected_index_list_pk
  from uil
  group by file_name
  
),
join_cols as (

  select s.*,partial_unexpected_index_list_value, partial_unexpected_index_list_pk,
  unexpected_index_list_value, unexpected_index_list_pk from source s 
  left join 
  puil_listagg p on s.file_name=p.file_name
  left join 
  uil_listagg u on s.file_name=u.file_name  

)
SELECT
    s.message:meta:active_batch_definition:batch_identifiers:default_identifier_name::string as default_identifier_name
  , s.message:meta:active_batch_definition:data_asset_name::string as data_asset_name
  , s.message:meta:active_batch_definition:data_connector_name::string as data_connector_name
  , s.message:meta:active_batch_definition:datasource_name::string as datasource_name
  , to_timestamp(s.message:meta:batch_markers:ge_load_time::string, 'YYYYMMDDThhmiss.FFZ') as ge_load_time
  , s.message:meta:checkpoint_id::string as checkpoint_id
  , s.message:meta:checkpoint_name::string as checkpoint_name
  , s.message:meta:expectation_suite_name::string as expectation_suite_name
  , s.message:meta:great_expectations_version::string as great_expectations_version
  , s.message:meta:run_id:run_name::string as run_name
  , to_timestamp(s.message:meta:run_id:run_time::string, 'YYYY-MM-DDThh:mi:ss.FF+00:00') as run_time
  , s.message:meta:validation_id::string as validation_id
  , to_timestamp(s.message:meta:validation_time::string, 'YYYYMMDDThhmiss.FFZ') as validation_time
  , s.value:exception_info:exception_message::string as exception_message
  , s.value:exception_info:exception_traceback::string as exception_traceback
  , s.value:exception_info:raised_exception::string as raised_exception
  , s.value:expectation_config:expectation_type::string as expectation_type
  , s.value:expectation_config:kwargs:batch_id::string as batch_id
  , s.value:expectation_config:kwargs:column::string as check_column
  , s.value:expectation_config:kwargs:regex::string as regex
  , s.value:expectation_config:kwargs:like_pattern::string as like_pattern
  , s.value:result:element_count::bigint as element_count
  , s.value:result:missing_count::bigint as missing_count
  , s.value:result:missing_percent::string as missing_percent
  , array_to_string(parse_json(replace(s.value:result:partial_unexpected_list::string, 'null', '"null"')), ', ') as partial_unexpected_list
  , s.value:result:unexpected_count::bigint as unexpected_count
  , array_to_string(parse_json(replace(s.value:result:unexpected_list::string, 'null', '"null"')), ', ') as unexpected_list
  , s.value:result:unexpected_percent::float as unexpected_percent
  , s.value:result:unexpected_percent_nonmissing::float as unexpected_percent_nonmissing
  , s.value:result:unexpected_percent_total::float as unexpected_percent_total
  , array_to_string(parse_json(s.value:result:unexpected_rows::string), ', ') as unexpected_rows
  , s.message:statistics:evaluated_expectations::bigint as evaluated_expectations
  , s.message:statistics:success_percent::bigint as success_percent
  , s.message:statistics:successful_expectations::bigint as successful_expectations
  , s.message:statistics:unsuccessful_expectations::bigint as unsuccessful_expectations  
  , s.value:success::string as success
  , nullif(rtrim(split_part(s.message:meta:expectation_suite_name::string, '[',  (case regexp_count(s.message:meta:expectation_suite_name::string, '\\[', 1) when 0 then null else -1 end) ), ']'),'') as test_primary_key
  , nullif(rtrim(split_part(split_part(s.message:meta:expectation_suite_name, '[', 1), '(', 2), ')'),'')::bigint as multi_scheme_id
  , nullif(s.partial_unexpected_index_list_value,'') as partial_unexpected_index_list_value
  , nullif(s.partial_unexpected_index_list_pk,'') as partial_unexpected_index_list_pk
  , nullif(s.unexpected_index_list_value,'') as unexpected_index_list_value
  , nullif(s.unexpected_index_list_pk,'') as unexpected_index_list_pk
  , s.message  
FROM join_cols as s