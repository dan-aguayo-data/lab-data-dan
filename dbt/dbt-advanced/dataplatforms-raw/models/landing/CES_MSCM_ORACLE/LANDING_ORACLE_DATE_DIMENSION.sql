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
    WHERE METADATA:"table-name"='DATE_DIMENSION' AND DATA is not null
)

SELECT
    N.DATA:DATE_D::DATE as DATE_D,
    N.DATA:DATE_J::bigint as DATE_J,
    N.DATA:DATE_V::string as DATE_V,
    N.DATA:YEAR_NUM::bigint as YEAR_NUM,
    N.DATA:QUARTER_NUM::bigint as QUARTER_NUM,
    N.DATA:MONTH_NUM::bigint as MONTH_NUM,
    N.DATA:MONTH_DESC::string as MONTH_DESC,
    N.DATA:ISO_WEEK_NUM::bigint as ISO_WEEK_NUM,
    N.DATA:ISO_YEAR_NUM::bigint as ISO_YEAR_NUM,
    N.DATA:DAY_OF_MONTH_NUM::bigint as DAY_OF_MONTH_NUM,
    N.DATA:DAY_OF_WEEK_NUM::bigint as DAY_OF_WEEK_NUM,
    N.DATA:DAY_OF_WEEK_DESC::string as DAY_OF_WEEK_DESC,
    N.DATA:DAY_TYPE_DESC::string as DAY_TYPE_DESC,
    N.DATA:YEAR_AND_QUARTER::string as YEAR_AND_QUARTER,
    N.DATA:YEAR_AND_MONTH::string as YEAR_AND_MONTH,
    N.DATA:ISO_YEAR_AND_WEEK::string as ISO_YEAR_AND_WEEK,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N