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
    WHERE METADATA:"table-name"='ADM_FLEXFIELDS_A' AND DATA is not null
)

SELECT
    nullif(N.DATA:FLEXFIELD_ID,'')::bigint as FLEXFIELD_ID,
    nullif(N.DATA:MULTI_SCHEME_ID,'')::bigint as MULTI_SCHEME_ID,
    nullif(N.DATA:SOURCE_TABLE,'')::string as SOURCE_TABLE,
    nullif(N.DATA:COLUMN_NAME,'')::string as COLUMN_NAME,
    nullif(N.DATA:COLUMN_LABEL,'')::string as COLUMN_LABEL,
    nullif(N.DATA:DATATYPE,'')::string as DATATYPE,
    nullif(N.DATA:DEFAULT_VALUE,'')::string as DEFAULT_VALUE,
    nullif(N.DATA:MIN_VALUE,'')::string as MIN_VALUE,
    nullif(N.DATA:MAX_VALUE,'')::string as MAX_VALUE,
    nullif(N.DATA:CATEGORY,'')::string as CATEGORY,
    nullif(N.DATA:CODE,'')::string as CODE,
    nullif(N.DATA:MANDATORY_FLAG,'')::string as MANDATORY_FLAG,
    nullif(N.DATA:EFFECTIVE_DATE_FROM,'')::DATE as EFFECTIVE_DATE_FROM,
    nullif(N.DATA:EFFECTIVE_DATE_TO,'')::DATE as EFFECTIVE_DATE_TO,
    nullif(N.DATA:ACTIVE_FLAG,'')::string as ACTIVE_FLAG,
    nullif(N.DATA:CREATED_BY,'')::string as CREATED_BY,
    nullif(N.DATA:CREATED_ON,'')::TIMESTAMP_NTZ as CREATED_ON,
    N.DATA:LAST_MODIFIED_BY::string as LAST_MODIFIED_BY,
    N.DATA:LAST_MODIFIED_ON::TIMESTAMP_NTZ as LAST_MODIFIED_ON,
    nullif(N.DATA:VIEW_ROLES,'')::string as VIEW_ROLES,
    nullif(N.DATA:EDIT_ROLES,'')::string as EDIT_ROLES,
    nullif(N.DATA:MULTI_VALUES,'')::string as MULTI_VALUES,
    nullif(N.DATA:DISPLAY_ORDER,'')::bigint as DISPLAY_ORDER,
    nullif(N.DATA:MANDATORY_SCREENS,'')::string as MANDATORY_SCREENS,
    nullif(N.DATA:AUDIT_TYPE,'')::string as AUDIT_TYPE,
    nullif(N.DATA:AUDIT_DATE,'')::TIMESTAMP_NTZ as AUDIT_DATE,
    nullif(N.DATA:AUDIT_USER,'')::string as AUDIT_USER,
    nullif(N.DATA:DISPLAY_SCREENS,'')::string as DISPLAY_SCREENS,
    nullif(N.DATA:LOV_VIEW_NAME,'')::string as LOV_VIEW_NAME,
    nullif(N.DATA:DISPLAY_IF,'')::string as DISPLAY_IF,
    nullif(N.DATA:MANDATORY_IF,'')::string as MANDATORY_IF,
    TO_TIMESTAMP(N.METADATA:timestamp::string) as METADATA_TIMESTAMP,
    N.METADATA:operation::string as METADATA_OPERATION
FROM SOURCE as N