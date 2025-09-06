{{
    config(
        materialized = 'incremental',
        incremental_strategy = 'merge',
        unique_key = 'ID'
    )
}}

WITH SOURCE as (

    SELECT *
    FROM {{ source('SNOWPIPE_PROD', 'RETURNIT_ANKER_PROD') }}

), 
Anker_Flatten as (

SELECT
    s.MESSAGE:Prop_4::string||'-'||s.MESSAGE:Prop_8::string||'-'||s.MESSAGE:Prop_9::string||'-'||s.MESSAGE:Prop_5::string||'-'||s.MESSAGE:Prop_7::string as ID,
    s.MESSAGE:Prop_1::string as POS,
    s.MESSAGE:Prop_2::string as GLN_MANUFACTURER,
    s.MESSAGE:Prop_3::string as KEY_ID,
    s.MESSAGE:Prop_4::string as ARTICLE_NUMBER,
    TO_TIMESTAMP(s.MESSAGE:Prop_5::string, 'YYYYMMDDHHMISSFF') as DATETIME,
    s.MESSAGE:Prop_6::string as SIGNATURE,
    s.MESSAGE:Prop_7::string as MACHINE_ID,
    s.MESSAGE:Prop_8::string as BATCH_NUMBER,
    s.MESSAGE:Prop_9::string as CAMERA_NUMBER,
    s.MESSAGE:Prop_10::string as DPG_MARK,
    s.MESSAGE:Prop_11::string as DPG_MARK_READ,
    s.MESSAGE:Prop_12::string as EJECTION_STATION_NO,
    s.MESSAGE:Prop_13::string as ARTICLE_ACCEPT_TYPE,
    s.MESSAGE:Prop_14::string as RB_REF,
    s.MESSAGE:Prop_15::string as IR_REF,
    s.MESSAGE:Prop_16::string as SUB_TYPE,
    s.MESSAGE:Prop_17::string as DEPOSIT_AMOUNT,
    s.MESSAGE:Prop_18::string as MATERIAL_TYPE_CODE,
    s.MESSAGE:Prop_19::string as DETECTED_MATERIAL_TYPE,
    s.MESSAGE:Prop_20::string as DETECTED_LENGTH,
    s.MESSAGE:Prop_21::string as DETECTED_HEIGHT,
    s.MESSAGE:Prop_22::string as DETECTED_WIDTH,
    (CASE WHEN s.FILE_NAME like '%nls%' then 'Non-Refundable' else 'Refundable' END) RECORD_TYPE,
    LANDED_DATETIME

FROM source as s
 ),
Anker_final as (
  
  select Anker_Flatten.*, MT.MATERIAL_TYPE from Anker_Flatten
  left join
  {{ source('LOOKUPS_PROD', 'RETURNIT_ANKER_MATERIAL_TYPE') }} MT 
  on MT.MATERIAL_TYPE_CODE=Anker_Flatten.MATERIAL_TYPE_CODE

)
SELECT
    s.*
FROM
    Anker_final s
{% if is_incremental() %}
WHERE
    NVL(s.LANDED_DATETIME, current_date) >= (SELECT dateadd(days, -7, max(LANDED_DATETIME)) FROM {{this}})
{% endif %}
QUALIFY row_number() OVER (PARTITION BY s.ID ORDER BY s.DATETIME desc) = 1

