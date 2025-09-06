{%- set trimmed_source_rel = model.name | replace("LANDING_ORACLE_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH SOURCE AS (
    SELECT
        *
    FROM
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_COEX') }}
    WHERE METADATA:"table-name"='FMT_VEHICLE_RATES' AND DATA is not null
)

SELECT
    N.DATA:VEHICLE_RATE_ID::bigint as VEHICLE_RATE_ID,
    N.DATA:AGREEMENT_NUMBER::string as AGREEMENT_NUMBER,
    N.DATA:RATE_TYPE_ID::bigint as RATE_TYPE_ID,
    N.DATA:RATE_UOM_ID::bigint as RATE_UOM_ID,
    N.DATA:RATE::float as RATE,
    N.DATA:START_DATE_ACTIVE::DATE as START_DATE_ACTIVE,
    nullif(N.DATA:END_DATE_ACTIVE,'')::DATE as END_DATE_ACTIVE,
    N.DATA:ORGANISATION_ID::bigint as ORGANISATION_ID,
    N.DATA:SCHEME_VEHICLE_TYPE_ID::bigint as SCHEME_VEHICLE_TYPE_ID,
    N.DATA:SCHEME_ID::bigint as SCHEME_ID,
    nullif(N.DATA:PO_LINE_NO,'')::bigint as PO_LINE_NO,
    nullif(N.DATA:PO_SHIPMENT_NO,'')::bigint as PO_SHIPMENT_NO,
    N.DATA:CREATED_BY::string as CREATED_BY,
    N.DATA:CREATED_ON::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N