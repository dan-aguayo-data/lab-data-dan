    
    
    
    
    WITH DETAIL_QUERY AS ( 
         SELECT
         PS.MULTI_SCHEME_ID
        ,R_TT.VALUE AS TAXONOMY
        ,lower(trim(C.EMAIL)) AS LOGIN_ID
        ,COALESCE(C.FIRST_NAME, '') || ' ' || COALESCE(C.LAST_NAME, '') AS FULL_NAME
        ,COALESCE(C.FIRST_NAME, '') FIRST_NAME
        ,COALESCE(C.LAST_NAME, '') LAST_NAME
        ,null AS SUPPLIER_NUMBER
        ,null as SITE_NUMBER  --PS.SITE_NUMBER
        , null as CONTRACT_MANAGER
        , null as CONTRACT_MANAGER_EMAIL         
        , CASE WHEN C.ACTIVE = 1 AND CR.ACTIVE = 1 THEN 1 ELSE 0 END AS ACTIVE         
        ,null as CREATED_BY       
        ,CR.CREATED_ON AS CREATED_ON_UTC      
        ,null AS LAST_MODIFIED_BY
        ,CR.LAST_MODIFIED_ON AS LAST_MODIFIED_ON_UTC
        FROM {{ source('CES_MSCM_ORACLE', 'MDT_CONTACTS') }} AS C
        LEFT JOIN {{ source('CES_MSCM_ORACLE', 'MDT_CONTACT_ROLES') }} AS CR 
        ON C.CONTACT_ID = CR.CONTACT_ID
        LEFT JOIN {{ source('CES_MSCM_ORACLE', 'MDT_PARTICIPANT_SITES') }} AS PS
        ON CR.PARTICIPANT_SITE_ID = PS.PARTICIPANT_SITE_ID
        LEFT JOIN {{ source('CES_MSCM_ORACLE', 'MDT_PARTICIPANTS') }} AS P
        ON CR.PARTICIPANT_ID = P.PARTICIPANT_ID
        LEFT JOIN {{ source('CES_MSCM_ORACLE', 'SCHEME_REF_CODES') }} AS R_T
        ON CR.ROLE_TYPE_ID = R_T.SCHEME_REF_CODES_ID
        LEFT JOIN {{ source('CES_MSCM_ORACLE', 'SCHEME_REF_CODES') }} AS R_TT
        ON PS.TAXONOMY_TYPE_ID = R_TT.SCHEME_REF_CODES_ID 
        where R_TT.VALUE = 'CRP'
        and CR.role_type_id = 1107
        --and PRIMARY = 1   --removed 04/03/2025 as column is not used in the B2B inferface, no description in oracle, and it is causing COEX miss important records
        and PS.MULTI_SCHEME_ID = 10000
        ) 
         SELECT
         MULTI_SCHEME_ID
        ,TAXONOMY
        ,LOGIN_ID
        ,FIRST_NAME
        ,LAST_NAME
        ,FULL_NAME
        ,SUPPLIER_NUMBER
        ,SITE_NUMBER 
        ,MAX(CONTRACT_MANAGER) CONTRACT_MANAGER
        ,MAX(CONTRACT_MANAGER_EMAIL) CONTRACT_MANAGER_EMAIL       
        ,MAX(ACTIVE) ACTIVE         
        ,MAX(CREATED_BY) CREATED_BY       
        ,MAX(CREATED_ON_UTC) CREATED_ON_UTC     
        ,MAX(LAST_MODIFIED_BY) LAST_MODIFIED_BY
        ,MAX(LAST_MODIFIED_ON_UTC) LAST_MODIFIED_ON_UTC
        FROM DETAIL_QUERY 
        GROUP BY
        FIRST_NAME
        ,LAST_NAME
         ,MULTI_SCHEME_ID
        ,TAXONOMY
        ,LOGIN_ID
        ,FULL_NAME
        ,SUPPLIER_NUMBER
        ,SITE_NUMBER 