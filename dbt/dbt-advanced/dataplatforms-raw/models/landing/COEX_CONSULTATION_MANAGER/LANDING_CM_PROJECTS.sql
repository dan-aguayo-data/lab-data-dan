{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH LATEST_FILE as (
    SELECT *
    FROM 
    {{ source('SNOWPIPE_PROD', 'COEX_CONSULTATION_MANAGER') }}
    WHERE lower(FILE_NAME) LIKE lower('%/cm-projects/%')
    QUALIFY row_number() OVER (PARTITION BY 'cm-projects' ORDER BY LANDED_DATETIME DESC) = 1
),
source as (
    SELECT *
    FROM 
    LATEST_FILE s,
    lateral flatten(input => s.message:results) f
)

SELECT 
        s.value:id::string as ID,
        s.value:databaseId::string as DATABASEID,
        s.value:visibility::string as VISIBILITY,
        s.value:deleted::string as DELETED,
        s.value:created::string as CREATED,
        s.value:createdBy:enabled::string as CREATEDBY_ENABLED,
        s.value:createdBy:identityType::string as CREATEDBY_IDENTITYTYPE,
        s.value:createdBy:identifier::string as CREATEDBY_IDENTIFIER,
        s.value:createdBy:displayName::string as CREATEDBY_DISPLAYNAME,
        s.value:modifiedBy:enabled::string as MODIFIEDBY_ENABLED,
        s.value:modifiedBy:identityType::string as MODIFIEDBY_IDENTITYTYPE,
        s.value:modifiedBy:identifier::string as MODIFIEDBY_IDENTIFIER,
        s.value:modifiedBy:displayName::string as MODIFIEDBY_DISPLAYNAME,
        s.value:name::string as NAME,
        s.value:timeZone::string as TIMEZONE,
        s.value:notes::string as NOTES,
        s.value:dateStart::string as DATESTART,
        s.value:dateEnd::string as DATEEND,
        s.value:projectGroup[0]:id::string as PROJECTGROUP_0_ID,
        s.value:projectGroup[0]:deleted::string as PROJECTGROUP_0_DELETED,
        s.value:projectGroup[0]:name::string as PROJECTGROUP_0_NAME,
        s.value:projectGroup[0]:hierarchy::string as PROJECTGROUP_0_HIERARCHY,
        s.value:projectGroup[0]:visibility::string as PROJECTGROUP_0_VISIBILITY,
        s.value:modified::string as MODIFIED,
        s.value:modifiedEndTime::string as MODIFIEDENDTIME,
        s.value:address:geoLocation::string as ADDRESS_GEOLOCATION,
        s.value:address:address::string as ADDRESS_ADDRESS,
        s.value:address:postCode::string as ADDRESS_POSTCODE,
        s.value:address:suburb::string as ADDRESS_SUBURB,
        s.value:address:state::string as ADDRESS_STATE,
        s.value:address:country::string as ADDRESS_COUNTRY,
        s.value:address:location::string as ADDRESS_LOCATION,
        s.value:address:dateGeocoded::string as ADDRESS_DATEGEOCODED,
        s.value:descriptor::string as DESCRIPTOR,
        s.value 

FROM    source as s
