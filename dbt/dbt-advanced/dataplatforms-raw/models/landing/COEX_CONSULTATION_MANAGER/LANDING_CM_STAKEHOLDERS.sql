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
    WHERE lower(FILE_NAME) LIKE lower('%/cm-stakeholders/%')
    QUALIFY row_number() OVER (PARTITION BY 'cmstakeholders' ORDER BY LANDED_DATETIME DESC) = 1
),
source as (
    SELECT *
    FROM 
    LATEST_FILE s,
    lateral flatten(input => s.message:results) f
)
SELECT 
        s.value:id::string as ID,
        s.value:title::string as TITLE,
        s.value:firstName::string as FIRSTNAME,
        s.value:lastName::string as LASTNAME,
        s.value:suffix::string as SUFFIX,
        s.value:salutation::string as SALUTATION,
        s.value:role::string as ROLE,
        s.value:organisation::string as ORGANISATION,
        s.value:bhPhone::string as BHPHONE,
        s.value:ahPhone::string as AHPHONE,
        s.value:mobile::string as MOBILE,
        s.value:fax::string as FAX,
        s.value:email::string as EMAIL,
        s.value:webaddress::string as WEBADDRESS,
        s.value:notes::string as NOTES,
        s.value:stakeholderGroups[0]:id::string as STAKEHOLDERGROUPS_0_ID,
        s.value:stakeholderGroups[0]:deleted::string as STAKEHOLDERGROUPS_0_DELETED,
        s.value:stakeholderGroups[0]:name::string as STAKEHOLDERGROUPS_0_NAME,
        s.value:stakeholderGroups[0]:hierarchy::string as STAKEHOLDERGROUPS_0_HIERARCHY,
        s.value:stakeholderGroups[0]:visibility::string as STAKEHOLDERGROUPS_0_VISIBILITY,
        s.value:privacyOption:id::string as PRIVACYOPTION_ID,
        s.value:privacyOption:deleted::string as PRIVACYOPTION_DELETED,
        s.value:privacyOption:name::string as PRIVACYOPTION_NAME,
        s.value:privacyOption:hierarchy::string as PRIVACYOPTION_HIERARCHY,
        s.value:privacyOption:visibility::string as PRIVACYOPTION_VISIBILITY,
        s.value:visibility::string as VISIBILITY,
        s.value:databaseId::string as DATABASEID,
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
        s.value:address:geoLocation:latitude::string as ADDRESS_GEOLOCATION_LATITUDE,
        s.value:address:geoLocation:longitude::string as ADDRESS_GEOLOCATION_LONGITUDE,
        s.value:address:address::string as ADDRESS_ADDRESS,
        s.value:address:postCode::string as ADDRESS_POSTCODE,
        s.value:address:suburb::string as ADDRESS_SUBURB,
        s.value:address:state::string as ADDRESS_STATE,
        s.value:address:country::string as ADDRESS_COUNTRY,
        s.value:address:location:type::string as ADDRESS_LOCATION_TYPE,
        s.value:address:location:value::string as ADDRESS_LOCATION_VALUE,
        s.value:address:location:latitude::string as ADDRESS_LOCATION_LATITUDE,
        s.value:address:location:longitude::string as ADDRESS_LOCATION_LONGITUDE,
        s.value:address:dateGeocoded::string as ADDRESS_DATEGEOCODED,
        s.value:descriptor::string as DESCRIPTOR,
        s.value:modified::string as MODIFIED,
        s.value:modifiedEndTime::string as MODIFIEDENDTIME,
        s.value:distributionLists[0]:id::string as DISTRIBUTIONLISTS_0_ID,
        s.value:distributionLists[0]:deleted::string as DISTRIBUTIONLISTS_0_DELETED,
        s.value:distributionLists[0]:name::string as DISTRIBUTIONLISTS_0_NAME,
        s.value:distributionLists[0]:hierarchy::string as DISTRIBUTIONLISTS_0_HIERARCHY,
        s.value:distributionLists[0]:visibility::string as DISTRIBUTIONLISTS_0_VISIBILITY,
        s.value:stakeholderGroups[1]:id::string as STAKEHOLDERGROUPS_1_ID,
        s.value:stakeholderGroups[1]:deleted::string as STAKEHOLDERGROUPS_1_DELETED,
        s.value:stakeholderGroups[1]:name::string as STAKEHOLDERGROUPS_1_NAME,
        s.value:stakeholderGroups[1]:hierarchy::string as STAKEHOLDERGROUPS_1_HIERARCHY,
        s.value:stakeholderGroups[1]:visibility::string as STAKEHOLDERGROUPS_1_VISIBILITY,
        s.value:stakeholderGroups[2]:id::string as STAKEHOLDERGROUPS_2_ID,
        s.value:stakeholderGroups[2]:deleted::string as STAKEHOLDERGROUPS_2_DELETED,
        s.value:stakeholderGroups[2]:name::string as STAKEHOLDERGROUPS_2_NAME,
        s.value:stakeholderGroups[2]:hierarchy::string as STAKEHOLDERGROUPS_2_HIERARCHY,
        s.value:stakeholderGroups[2]:visibility::string as STAKEHOLDERGROUPS_2_VISIBILITY,
        s.value:relatedProjects[0]:id::string as RELATEDPROJECTS_0_ID,
        s.value:relatedProjects[0]:value::string as RELATEDPROJECTS_0_VALUE,
        s.value:address:geoLocation::string as ADDRESS_GEOLOCATION,
        s.value:address:location::string as ADDRESS_LOCATION,
        s.value 

FROM    source as s
