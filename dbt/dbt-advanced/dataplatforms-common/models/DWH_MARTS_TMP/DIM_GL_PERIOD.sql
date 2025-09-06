{{ config(
    post_hook=[
        "ALTER TABLE {{ this }} SET TAG DWH_GOLD.DATA_MART = 'SCHEME_FINANCE'"
    ]
) 
}}

--############ SCHEME_FINANCE MART ############--



WITH sawith0 AS (
    SELECT
        t288012.c251991545 AS c1,
        t288012.c31780499  AS c2,
        t288012.c218311018 AS c3,
        t288012.c42913078  AS c4,
        t288012.c221858730 AS c5,
        t288012.c169246525 AS c6,
        t288012.c355931595 AS c7,
        t288012.c247927417 AS c9,
        t288012.c294016833 AS c10,
        t288012.c510997710 AS c11,
        t288012.c278163189 AS c13,
        t288012.c119172435 AS c14,
        t288012.pka_fiscalperiodsetname0 AS c15
    FROM
        (
            SELECT
                v212661565.FISCAL_PERIOD_NAME        AS c251991545,
                v212661565.FISCAL_PERIOD_FISCAL_PERIOD_START_DATE  AS c31780499,
                v212661565.FISCAL_PERIOD_FISCAL_PERIOD_END_DATE    AS c218311018,
                v212661565.FISCAL_PERIOD_FISCAL_PERIOD_NUMBER      AS c42913078,
                v212661565.FISCAL_QUARTER_FISCAL_QUARTER_START_DATE AS c221858730,
                v212661565.FISCAL_QUARTER_FISCAL_QUARTER_END_DATE   AS c169246525,
                v212661565.FISCAL_QUARTER_FISCAL_QUARTER_NUMBER     AS c355931595,
                v212661565.FISCAL_YEAR_FISCAL_YEAR_START_DATE    AS c247927417,
                v212661565.FISCAL_YEAR_FISCAL_YEAR_END_DATE      AS c294016833,
                v212661565.FISCAL_YEAR_FISCAL_YEAR_NUMBER       AS c510997710,
                v212661565.GL_CALENDARS_USER_PERIOD_SET_NAME     AS c278163189,
                v212661565.FISCAL_PERIOD_ADJUSTMENT_PERIOD_FLAG    AS c119172435,
                v212661565.FISCAL_PERIOD_SET_ID      AS pka_fiscalperiodsetid0,
                v212661565.FISCAL_PERIOD_SET_NAME    AS pka_fiscalperiodsetname0,
                v212661565.FISCAL_PERIOD_TYPE        AS pka_fiscalperiodtype0,
                v212661565.GL_CALENDARS_CALENDAR_ID             AS pka_glcalendarscalendarid0,
                v212661565.GL_CALENDARS_PERIOD_SET_ID           AS pka_glcalendarsperiodsetid0,
                v212661565.GL_CALENDARS_PERIOD_TYPE_ID           AS pka_glcalendarsperiodtypeid0
            FROM
             {{source('CES_ERP_FREQ_FSCM_FINGLCALACC','GLFISCAL_PERIOD_PVO')}}   v212661565
            WHERE v212661565._FIVETRAN_DELETED = FALSE
        ) t288012


)
SELECT DISTINCT
    --Key naming convention applied for clarity "<TABLE NAME>_KEY". Dbt Util applied.
    --Dimension Key
    {{ dbt_utils.generate_surrogate_key(["d1.c1 || d1.c15"]) }}  AS DIM_GL_PERIOD_KEY,

    --Natural Key
    d1.c1 AS FISCAL_PERIOD,
    d1.c13 AS FISCAL_PERIOD_SET_NAME,

    --Attributes 
    d1.c2 AS FISCAL_PERIOD_START_DATE,
    d1.c3 AS FISCAL_PERIOD_END_DATE,
    d1.c4 AS FISCAL_PERIOD_NUM,
    d1.c5 AS FISCAL_QUARTER_START_DATE,
    d1.c6 AS FISCAL_QUARTER_END_DATE,
    d1.c7 AS FISCAL_QUARTER_NUM,
    concat(concat(concat('Qtr', CAST(d1.c7 AS VARCHAR(2))), '-'), substr(CAST(d1.c11 AS VARCHAR(4)), 3, 2)) AS FISCAL_QUARTER,
    d1.c9 AS FISCAL_YEAR_START_DATE,
    d1.c10 AS FISCAL_YEAR_END_DATE,
    d1.c11 AS FISCAL_YEAR,
    CASE
        WHEN d1.c14 = 'Y' THEN
            'Yes'
        ELSE
            'No'
    END AS ADJ_PERIOD_IND,
    --Metadata Attributes
    SYSDATE() AS INSERT_UTC_DATETIME  
FROM
    sawith0 d1
ORDER BY d1.c1