{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source AS (
    SELECT *
    FROM
        {{ source('SNOWPIPE_PROD', 'COEX_CONSULTATION_MANAGER') }} s,
        lateral flatten(input => s.message:results) f
    WHERE
        lower(FILE_NAME) LIKE lower('%/cm-actions/%')
)


SELECT  DISTINCT
        s.value:id::string as ID,
        s.value:initiated::string as INITIATED,
        s.value:actionRequested::string as ACTIONREQUESTED,
        s.value:deadline::string as DEADLINE,
        s.value:actionTaken::string as ACTIONTAKEN,
        s.value:didtheoperatorrespondwithinbusinessdays:id::string as DIDTHEOPERATORRESPONDWITHINBUSINESSDAYS_ID,
        s.value:didtheoperatorrespondwithinbusinessdays:deleted::string as DIDTHEOPERATORRESPONDWITHINBUSINESSDAYS_DELETED,
        s.value:didtheoperatorrespondwithinbusinessdays:name::string as DIDTHEOPERATORRESPONDWITHINBUSINESSDAYS_NAME,
        s.value:didtheoperatorrespondwithinbusinessdays:hierarchy::string as DIDTHEOPERATORRESPONDWITHINBUSINESSDAYS_HIERARCHY,
        s.value:didtheoperatorrespondwithinbusinessdays:visibility::string as DIDTHEOPERATORRESPONDWITHINBUSINESSDAYS_VISIBILITY,
        s.value:resolved::string as RESOLVED,
        s.value:qas::string as QAS,
        s.value:notified::string as NOTIFIED,
        s.value:actionStatus:id::string as ACTIONSTATUS_ID,
        s.value:actionStatus:deleted::string as ACTIONSTATUS_DELETED,
        s.value:actionStatus:name::string as ACTIONSTATUS_NAME,
        s.value:actionStatus:hierarchy::string as ACTIONSTATUS_HIERARCHY,
        s.value:actionStatus:visibility::string as ACTIONSTATUS_VISIBILITY,
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
        s.value:modified::string as MODIFIED,
        s.value:modifiedEndTime::string as MODIFIEDENDTIME,
        s.value:assignedByAction:id::string as ASSIGNEDBYACTION_ID,
        s.value:assignedByAction:value::string as ASSIGNEDBYACTION_VALUE,
        s.value:assignedToAction:id::string as ASSIGNEDTOACTION_ID,
        s.value:assignedToAction:value::string as ASSIGNEDTOACTION_VALUE,
        s.value:relatedProjects[0]:id::string as RELATEDPROJECTS_0_ID,
        s.value:relatedProjects[0]:value::string as RELATEDPROJECTS_0_VALUE,
        s.value:elapsed::string as ELAPSED,
        s.value:performance::string as PERFORMANCE,
        s.value:descriptor::string as DESCRIPTOR,
        s.value:assignedCcAction[0]:id::string as ASSIGNEDCCACTION_0_ID,
        s.value:assignedCcAction[0]:value::string as ASSIGNEDCCACTION_0_VALUE,
        s.value:assignedCcAction[1]:id::string as ASSIGNEDCCACTION_1_ID,
        s.value:assignedCcAction[1]:value::string as ASSIGNEDCCACTION_1_VALUE,
        s.value:assignedCcAction[2]:id::string as ASSIGNEDCCACTION_2_ID,
        s.value:assignedCcAction[2]:value::string as ASSIGNEDCCACTION_2_VALUE,
        s.value:assignedCcAction[3]:id::string as ASSIGNEDCCACTION_3_ID,
        s.value:assignedCcAction[3]:value::string as ASSIGNEDCCACTION_3_VALUE,
        s.value:assignedCcAction[4]:id::string as ASSIGNEDCCACTION_4_ID,
        s.value:assignedCcAction[4]:value::string as ASSIGNEDCCACTION_4_VALUE,
        s.value:assignedCcAction[5]:id::string as ASSIGNEDCCACTION_5_ID,
        s.value:assignedCcAction[5]:value::string as ASSIGNEDCCACTION_5_VALUE,
        s.value:assignedCcAction[6]:id::string as ASSIGNEDCCACTION_6_ID,
        s.value:assignedCcAction[6]:value::string as ASSIGNEDCCACTION_6_VALUE,
        s.value:assignedToAction::string as ASSIGNEDTOACTION,
        s.value:assignedCcAction[7]:id::string as ASSIGNEDCCACTION_7_ID,
        s.value:assignedCcAction[7]:value::string as ASSIGNEDCCACTION_7_VALUE,
        s.value:assignedByAction::string as ASSIGNEDBYACTION,
        s.value:didtheoperatorrespondwithinbusinessdays::string as DIDTHEOPERATORRESPONDWITHINBUSINESSDAYS,
        s.value 

FROM    source as s
