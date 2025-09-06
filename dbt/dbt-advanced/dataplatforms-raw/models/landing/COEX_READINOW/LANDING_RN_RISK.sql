{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH source AS (
    SELECT *
    FROM 
        {{ source('SNOWPIPE_PROD', 'COEX_READINOW') }} s,
        lateral flatten(input => s.message:data) f
    WHERE
        lower(FILE_NAME) LIKE lower('%/rn_risk/%')
)


SELECT 
        s.message:correlationCode::string as CORRELATION_CODE,         
        s.value:approvalStatus::string as  APPROVAL_STATUS,
        s.value:approver:name::string as  APPROVER_NAME,
        s.value:businessUnit:name::string as  BUSINESS_UNIT,
        s.value:causeFactors::string as  CAUSE_FACTORS,
        s.value:controls[0]:name::string as  CONTROLS,
        s.value:effectOnObjective::string as  EFFECT_ON_OBJECTIVE,
        s.value:inherentConsequencePeople::string as  INHERENT_CONSEQUENCE_PEOPLE,
        s.value:inherentImpact::string as  INHERENT_IMPACT,
        s.value:inherentLikelihood::string as  INHERENT_LIKELIHOOD,
        s.value:inherentRating::string as  INHERENT_RATING,
        s.value:inherentRiskValue::string as  INHERENT_RISK_VLAUE,
        s.value:lastApprovedBy:name::string as LAST_APPROVED_BY,
        s.value:lastApprovedDate::date as LAST_APPROVED_DATE,
        s.value:lid::string as LID,
        s.value:logEntriesForObject:name::string as LOG_ENTRIES_FOR_OBJECT,
        s.value:nextReviewDate::date as  NEXT_REVIEW_DATE,
        s.value:owner:name::string as  OWNER_NAME,
        s.value:residualConsequencePeople::string as  RESIDUAL_CONSEQUENCE_PEOPLE,
        s.value:residualImpact::string as  RESIDUAL_IMPACT,
        s.value:residualLikelihood::string as  RESIDUAL_LIKELIHOOD,
        s.value:residualRating::string as  RESIDUAL_RATING,
        s.value:residualRiskValue::string as  RESIDUAL_RISK_VALUE,
        s.value:reviewCycle::string as  REVIEW_CYCLE,
        s.value:riskCategory::string as  RISK_CATEGORY,
        s.value:riskID::string as  RISK_ID,
        s.value:riskLibrary:name::string as  RISK_LIBRARY_NAME,
        s.value:riskResponse::string as  RISK_RESPONSE,
        s.value:riskSubCategory::string as  RISK_SUB_CATEGORY,
        s.message:type:application:name::string as  APPLICATION_NAME,      
        s.value,
        s.message
FROM    source as s