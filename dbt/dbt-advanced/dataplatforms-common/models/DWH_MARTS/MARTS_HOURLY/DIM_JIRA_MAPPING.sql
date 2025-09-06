--############ CRM MART ############--

{{ config(
    post_hook=[
        "ALTER TABLE {{ this }} SET TAG DWH_GOLD.DATA_MART = 'CRM'"
    ]
) 
}}


SELECT
--Key naming convention applied for clarity "<TABLE NAME>_KEY". Dbt Util applied.
--Dimension Key
  {{ dbt_utils.generate_surrogate_key(['CRM.ID']) }} AS DIM_JIRA_MAPPING_KEY

--Natural Key
, CRM.ID AS ID

--Attributes
, CRM.MULTI_SCHEME_ID AS MULTI_SCHEME_ID
, CRM.SCHEME AS SCHEME
, CRM.ZENDESK_TICKET_ID AS ZENDESK_TICKET_ID
, NVL(CRM.JIRA_TICKET_ID, '-') AS JIRA_TICKET_ID

--Metadata Attributes
, SYSDATE() AS INSERT_UTC_DATETIME

FROM (

    SELECT
    CASE WHEN JIRA_TICKET_ID IS NULL THEN ZENDESK_TICKET_ID ELSE ZENDESK_TICKET_ID || '-' || JIRA_TICKET_ID END AS ID,
    * FROM (
        SELECT 
          CRM.MULTI_SCHEME_ID AS MULTI_SCHEME_ID
        , CRM.SCHEME AS SCHEME
        , CRM.TICKET_ID AS ZENDESK_TICKET_ID
        , CASE WHEN NULLIF(CRM.JIRA_TICKET_ID, '') IS NULL THEN NULL ELSE C.VALUE::string END AS JIRA_TICKET_ID
        FROM {{ ref('CRM_INCIDENTS') }} AS CRM, LATERAL FLATTEN(INPUT=>SPLIT(CRM.JIRA_TICKET_ID, ', ')) C
    )
    
) CRM

