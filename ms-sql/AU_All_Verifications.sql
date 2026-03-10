
WITH AUS_Verification AS (
    SELECT
        c.Id AS OID,
        s.ID AS SupplierId,
        s.customerId AS CustomerId,
        s.accountKey,
        s.supplierName,
        s.VerificationStatus,
        s.VerificationType,
        s.VerificationStatusDate,
        s.country,
        s.isAlias,
        COALESCE(s.VerifiedDate, s.CreatedAt) AS Verified_Or_Created_Date,
        c.DateCreated AS onboardingDate,
        CASE WHEN c.Id IS NOT NULL THEN 1 ELSE 0 END AS Onboarding,
        CASE
            WHEN s.VerificationStatus = '4' THEN 'Crossmatched'
            WHEN s.authorizerComment LIKE '%Auto-Verification%' THEN 'AVS'
            WHEN s.authorizerComment LIKE '%supplier: Verified account details%' THEN 'Confirmation'
            WHEN w.accountKey IS NOT NULL THEN 'Whitelist Matched'
            WHEN s.isAlias = '1' THEN 'Self-Certify'
            ELSE 'Other'
        END AS NonOnboarding,
        CASE
            WHEN s.authorizerComment LIKE '%Eftsure Support: Company setup import%' THEN 'VMF'
            WHEN s.supplierName LIKE '%From Payment Record%' THEN 'Payment File'
            WHEN s.authorizerComment LIKE '%Added supplier record%' THEN 'Add Supplier'
            WHEN s.authorizerComment LIKE '%Updated Supplier reference:%' THEN 'Payment File'
            ELSE 'Other'
        END AS Non_Onboarding_Source,
        s.AccountCodeType,
        CASE
            WHEN s.AccountCodeType = '8'   THEN 'South Africa'
            WHEN s.AccountCodeType = '9'   THEN 'Australia'
            WHEN s.AccountCodeType = '1'   THEN 'New Zealand'
            WHEN s.AccountCodeType = '177'
              OR (s.AccountCodeType = '2' AND s.Country = 'GBR') THEN 'United Kingdom'
            WHEN s.AccountCodeType = '202'
              OR (s.AccountCodeType = '2' AND s.Country = '102') THEN 'Ireland'
            WHEN s.AccountCodeType = '3'   THEN 'Canada'
            WHEN s.AccountCodeType = '277' THEN 'Philippines'
            WHEN s.AccountCodeType = '298' THEN 'Singapore'
            WHEN s.AccountCodeType = '4'   THEN 'United States'
            WHEN s.AccountCodeType = '11'  THEN s.country
            ELSE 'Other'
        END AS InternationalVerification,
        CASE
            WHEN s.VerifiedDate IS NOT NULL THEN 'VerifiedDate'
            ELSE 'CreatedAt'
        END AS VerifiedDate_Source,
        CASE WHEN s.VerifiedDate IS NOT NULL THEN 1 ELSE 0 END AS VerifiedDate_IsPrimary,
        CASE 
            WHEN c.DateCreated IS NOT NULL 
             AND (COALESCE(s.VerifiedDate, s.CreatedAt) IS NULL 
                  OR c.DateCreated > COALESCE(s.VerifiedDate, s.CreatedAt))
            THEN c.DateCreated
            ELSE COALESCE(s.VerifiedDate, s.CreatedAt)
        END AS Verification_estimate_date,
        s.VerifiedDate,
        s.CreatedAt,
        s.accountCountry,
        CASE
            WHEN c.RequestDetailsChangeJson IS NOT NULL THEN 'CustomerRequestChange'
            WHEN c.OnboardingType = 1 THEN 'V1'
            WHEN c.OnboardingType = 2 THEN 'V2'
            WHEN c.OnboardingType = 3 THEN 'V3'
            WHEN c.OnboardingType = 4 THEN 'Document'
            ELSE NULL
        END AS OnboardingSource,
        spm.country AS SupplierPaymentMethodsCounty,
        NULL AS OnboardingStatus,
        NULL AS Geo
    FROM [EFTSURE_DEV].[dbo].[SUPPLIERS] AS s
    LEFT JOIN [PORTAL_PROD].[dbo].[CustomerOnboardings] AS c
        ON s.publicId = c.EmailVerificationPublicId
    LEFT JOIN [PORTAL_PROD].[dbo].[SupplierPaymentMethods] AS spm
        ON c.PaymentMethod_Id = spm.Id
    LEFT JOIN [EFTSURE_DEV].[dbo].[WHITELIST] w
        ON s.accountKey = w.accountKey
    WHERE (c.DateCreated >= '2016-01-01'
       OR  COALESCE(s.VerifiedDate, s.CreatedAt) >= '2016-01-01')
        AND NOT EXISTS (
            SELECT 1
            FROM [EFTSURE_DEV].[dbo].[customers] AS cu
            WHERE cu.id = s.customerId
              AND (cu.groupId = '12'
                OR cu.companyName LIKE '%healthcheck%'
                OR cu.companyName LIKE 'Test%'
                OR cu.companyName LIKE '% Test%'
                OR ISNULL(cu.custInactive, 0) <> 0)
        )
        AND NOT EXISTS (
            SELECT 1
            FROM [EFTSURE_DEV].[dbo].[users] AS u
            WHERE u.customer = s.customerId
              AND (u.email LIKE '%@eftsure.com.au'
                OR u.email = 'markc@eteam.com.au')
        )
),

AUS_Onboarding_Pending AS (
    SELECT
        c.Id AS OID,
        c.CustomerId,
        c.DateCreated AS Verification_estimate_date,
        '1' AS Onboarding,
        spm.country AS SupplierPaymentMethodsCounty,
        spm.CountrySpecificCodeType AS AccountCodeType,
        NULL AS NonOnboarding,
        'Pending' AS OnboardingStatus,
        CASE
            WHEN c.OnboardingType = 1 THEN 'V1'
            WHEN c.OnboardingType = 2 THEN 'V2'
            WHEN c.OnboardingType = 3 THEN 'V3'
            WHEN c.OnboardingType = 4 THEN 'Document'
            ELSE NULL
        END AS OnboardingSource,
        'AUS' AS Geo
    FROM [PORTAL_PROD].[dbo].[CustomerOnboardings] AS c
    JOIN [PORTAL_PROD].[dbo].[SupplierPaymentMethods] AS spm
        ON c.PaymentMethod_Id = spm.Id
    WHERE c.DateCreated > '2016-01-01'
        AND NOT EXISTS (
            SELECT 1
            FROM [EFTSURE_DEV].[dbo].[SUPPLIERS] AS s
            WHERE s.publicId = c.EmailVerificationPublicId
        )
        AND c.CurrentOnboardingStatus IN ('-2','-1','1','2','3','5','7','8','9','10','11','12')
        AND c.RequestDetailsChangeJson IS NULL

    UNION

    SELECT
        c.Id AS OID,
        c.CustomerId,
        c.DateCreated AS Verification_estimate_date,
        '1' AS Onboarding,
        spm.country AS SupplierPaymentMethodsCounty,
        spm.CountrySpecificCodeType AS AccountCodeType,
        NULL AS NonOnboarding,
        CASE CurrentOnboardingStatus
            WHEN 6   THEN 'HasntRespondedToReminder'
            WHEN -3  THEN 'Deregistered'
            WHEN -2  THEN 'Cancelled'
            WHEN -1  THEN 'Rejected'
            WHEN 0   THEN 'Pending'
            WHEN 1   THEN 'UnderReview'
            WHEN 2   THEN 'Incomplete'
            WHEN 3   THEN 'Accepted'
            WHEN 4   THEN 'SmsCodeRequired'
            WHEN 7   THEN 'AwaitingVerification'
            WHEN 8   THEN 'AwaitingVerificationApproval'
            WHEN 9   THEN 'Awaiting Customer Assistance / VerificationRejected'
            WHEN 10  THEN 'UnderInternalReview'
            WHEN 11  THEN 'AwaitingCustomerAssistance'
            WHEN 12  THEN 'FailedEftsureVerification'
            WHEN 17  THEN 'PreApproval'
            WHEN 99  THEN 'All'
            WHEN -5  THEN 'EmailInvitationFailed'
        END AS OnboardingStatus,
        CASE
            WHEN c.RequestDetailsChangeJson IS NOT NULL THEN 'CustomerRequestChange'
            WHEN c.OnboardingType = 1 THEN 'V1'
            WHEN c.OnboardingType = 2 THEN 'V2'
            WHEN c.OnboardingType = 3 THEN 'V3'
            WHEN c.OnboardingType = 4 THEN 'Document'
            ELSE NULL
        END AS OnboardingSource,
        'AUS' AS Geo
    FROM [PORTAL_PROD].[dbo].[CustomerOnboardings] AS c
    JOIN [PORTAL_PROD].[dbo].[SupplierPaymentMethods] AS spm
        ON c.PaymentMethod_Id = spm.Id
    WHERE c.DateCreated > '2016-01-01'
        AND c.RequestDetailsChangeJson IS NOT NULL
),

-- Combine A (selected columns from AUS_Verification) + B (AUS_Onboarding_Pending)
Combined AS (
    -- A: from AUS_Verification
    SELECT
        accountCountry,
        OID,
        Verification_estimate_date,
        Onboarding,
        country AS [Country Name],
        AccountCodeType,
        NonOnboarding,
        Geo,
        VerificationStatus,
        Non_Onboarding_Source,
        OnboardingSource,
        SupplierId,
        SupplierPaymentMethodsCounty,
        CustomerId,
        NULL AS OnboardingStatus
    FROM AUS_Verification

    UNION ALL

    -- B: from AUS_Onboarding_Pending
    SELECT
        NULL AS accountCountry,
        OID,
        Verification_estimate_date,
        Onboarding,
        NULL AS [Country Name],
        AccountCodeType,
        NonOnboarding,
        Geo,
        NULL AS VerificationStatus,
        NULL AS Non_Onboarding_Source,
        OnboardingSource,
        NULL AS SupplierId,
        SupplierPaymentMethodsCounty,
        CustomerId,
        OnboardingStatus
    FROM AUS_Onboarding_Pending
), AUS_Auto AS (
    SELECT
        c.Id AS OID,  -- using CustomerOnboarding_Id = c.Id
        CASE
            WHEN i.Notes LIKE '%(using Bank Link)%' THEN 'Yodlee'
            WHEN i.Notes LIKE 'Onboarding has passed Auto-Verification (AVS)' THEN 'AVS'
            WHEN i.Notes LIKE '%Onboarding has been Auto-Verified (AVIO)%' THEN 'AVIO'
            WHEN i.Notes LIKE '%Onboarding has been Auto-Verified (AVWO)%' THEN 'AVWO'
            ELSE 'Other'
        END AS Onboarding_Auto_Type
    FROM [PORTAL_PROD].[dbo].[CustomerOnboardingInteractions] i
    JOIN [PORTAL_PROD].[dbo].[CustomerOnboardings] c
        ON i.CustomerOnboarding_Id = c.Id
    WHERE (
            i.Notes LIKE '% Auto-Verified%'
         OR i.Notes LIKE '%Auto-Accepted%'
         OR i.Notes LIKE '%(using Bank Link)%'
         OR i.Notes LIKE '%Onboarding has passed Auto-Verification (AVS)%'
    )
    AND i.Date > c.DateCreated
    AND c.DateCreated > '2016-01-01'
), Combined_Pre_Final AS (

-- Then update the final SELECT:

SELECT
    cb.*,
    ROW_NUMBER() OVER (ORDER BY cb.OID ASC, cb.Verification_estimate_date ASC) AS RecordID,
    
    CASE cb.[Country Name]
        WHEN 'AU' THEN 'AUS'
        WHEN 'US' THEN 'USA'
        WHEN 'NZ' THEN 'NZL'
        WHEN 'GB' THEN 'GBR'
        ELSE cb.[Country Name]
    END AS [Country Name Clean],

    CASE
        WHEN cb.Non_Onboarding_Source = 'VMF' THEN 'VMF'
        WHEN cb.Onboarding = '1' THEN 'Onboarding'
        ELSE 'Other Non-Onboarding'
    END AS [Verification Category],

    COALESCE(cb.accountCountry, cb.[Country Name], cb.Geo) AS [Verification Country],

    CASE
        WHEN cb.Onboarding = '1' THEN cb.OnboardingSource
        ELSE cb.Non_Onboarding_Source
    END AS [Source],

    -- Onboarding Method
    CASE
        WHEN cb.OID IS NULL THEN NULL
        WHEN aa.Onboarding_Auto_Type IS NOT NULL THEN aa.Onboarding_Auto_Type
        ELSE 'Manual'
    END AS [Onboarding Method],    CASE cb.VerificationStatus
        WHEN 0  THEN 'RED'
        WHEN 1  THEN 'GREEN'
        WHEN 2  THEN 'ORANGE'
        WHEN 3  THEN 'RED'
        WHEN 4  THEN 'GREEN'
        WHEN 5  THEN 'ORANGE'
        WHEN 6  THEN 'ORANGE'
        WHEN 8  THEN 'INACTIVE (RED)'
        WHEN 10 THEN 'ORANGE'
        WHEN 11 THEN 'ORANGE'
        WHEN 12 THEN 'RED'
        WHEN 13 THEN NULL
        WHEN 14 THEN 'ORANGE'
        WHEN 15 THEN 'RED'
        WHEN 16 THEN 'ORANGE'
        WHEN 17 THEN 'RED'
        WHEN 18 THEN NULL
        WHEN 19 THEN NULL
        WHEN 20 THEN 'Self-Certify'
        WHEN 21 THEN 'Self-Certify'
        WHEN 22 THEN 'Self-Certify'
        WHEN 23 THEN 'Self-Certify'
        WHEN 24 THEN 'GREEN'
        WHEN 25 THEN 'Self-Certify'
        WHEN 26 THEN 'Self-Certify'
        WHEN 31 THEN 'RED'
        WHEN 33 THEN 'GREEN'
        WHEN 34 THEN NULL
        WHEN 99 THEN 'ORANGE'
        ELSE NULL
    END AS [Thumb Status],

    -- Sub Verification_Method
    CASE
        WHEN cb.Onboarding = '1' THEN
            CASE
                WHEN cb.OnboardingStatus = 'Pending' THEN 'Pending'
                ELSE CASE
                    WHEN cb.OID IS NULL THEN NULL
                    WHEN aa.Onboarding_Auto_Type IS NOT NULL THEN aa.Onboarding_Auto_Type
                    ELSE 'Manual'
                END
            END
        ELSE
            CASE
                WHEN CASE cb.VerificationStatus
                        WHEN 20 THEN 'Self-Certify' WHEN 21 THEN 'Self-Certify'
                        WHEN 22 THEN 'Self-Certify' WHEN 23 THEN 'Self-Certify'
                        WHEN 25 THEN 'Self-Certify' WHEN 26 THEN 'Self-Certify'
                     END = 'Self-Certify'
                    THEN 'Self-Certify'
                WHEN cb.VerificationStatus IN (2, 5, 6, 10, 11, 14, 16, 99)  -- ORANGE statuses
                  OR cb.OnboardingStatus = 'Pending'
                    THEN 'Pending'
                ELSE COALESCE(
                    CASE
                        WHEN cb.OID IS NULL THEN NULL
                        WHEN aa.Onboarding_Auto_Type IS NOT NULL THEN aa.Onboarding_Auto_Type
                        ELSE 'Manual'
                    END,
                    cb.NonOnboarding
                )
            END
    END AS [Sub Verification_Method]

FROM Combined cb
LEFT JOIN AUS_Auto aa ON cb.OID = aa.OID

)

SELECT 
* ,
CASE [Sub Verification_Method]
    WHEN 'Pending'           THEN 'Pending'
    WHEN 'AVIO'              THEN 'Auto'
    WHEN 'AVWO'              THEN 'Auto'
    WHEN 'Yodlee'            THEN 'Auto'
    WHEN 'Manual'            THEN 'Manual'
    WHEN 'Crossmatched'      THEN 'Auto'
    WHEN 'Whitelist Matched' THEN 'Auto'
    WHEN 'AVS'               THEN 'Auto'
    WHEN 'Confirmation'      THEN 'Email confirmation'
    WHEN 'Self-Certify'      THEN 'Self-Certify'
    ELSE NULL
END AS [Auto_Manual_Category]


FROM Combined_Pre_Final

