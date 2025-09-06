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
        {{ source('LANDING_ORACLE', 'AWS_RDS_STAGE_CES_MSCM') }}
    WHERE METADATA:"table-name"='PRODUCT_STAGING' AND DATA is not null
)

SELECT
    N.DATA:PRODUCT_STAGING_ID::bigint as PRODUCT_STAGING_ID,
    nullif(N.DATA:ID,'')::string as ID,
    nullif(N.DATA:PRODUCT_GROUP_ID,'')::string as PRODUCT_GROUP_ID,
    nullif(N.DATA:NAME,'')::string as NAME,
    nullif(N.DATA:EAN,'')::string as EAN,
    nullif(N.DATA:NATIONAL_REFUND_LOGO,'')::bigint as NATIONAL_REFUND_LOGO,
    nullif(N.DATA:SA_REFUND_LOGO,'')::bigint as SA_REFUND_LOGO,
    nullif(N.DATA:GLASS_COLOUR,'')::string as GLASS_COLOUR,
    nullif(N.DATA:PET_COLOUR,'')::string as PET_COLOUR,
    nullif(N.DATA:DESIGNATED_CAPACITY_ML,'')::float as DESIGNATED_CAPACITY_ML,
    nullif(N.DATA:HEIGHT_MM,'')::float as HEIGHT_MM,
    nullif(N.DATA:DIAMETER_MM,'')::float as DIAMETER_MM,
    nullif(N.DATA:WEIGHT_GM,'')::float as WEIGHT_GM,
    nullif(N.DATA:PRODUCT_GROUP_OTHER,'')::string as PRODUCT_GROUP_OTHER,
    nullif(N.DATA:GLASS_COLOUR_OTHER,'')::string as GLASS_COLOUR_OTHER,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:SUPPLIER_PARTICIPANT_ID,'')::bigint as SUPPLIER_PARTICIPANT_ID,
    nullif(N.DATA:SCHEME_PRODUCT_ID,'')::string as SCHEME_PRODUCT_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N