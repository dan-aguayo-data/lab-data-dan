SELECT
    c.Id AS OID,
    s.ID AS SupplierId,
    s.customerId,
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
        WHEN authorizerComment LIKE '%supplier: Verified account details%' THEN 'Confirmation'
        WHEN w.accountKey IS NOT NULL THEN 'Whitelist Matched'
        WHEN s.isAlias = '1' THEN 'Self-Certify'
        ELSE 'Other'
    END AS NonOnboarding,
    CASE
        WHEN s.authorizerComment LIKE '%Eftsure Support: Company setup import%' THEN 'VMF'
        WHEN supplierName LIKE '%From Payment Record%' THEN 'Payment File'
        WHEN s.authorizerComment LIKE '%Added supplier record%' THEN 'Add Supplier'
        WHEN s.authorizerComment LIKE '%Updated Supplier reference:%' THEN 'Payment File'
        ELSE 'Other'
    END AS Non_Onboarding_Type,
    s.AccountCodeType,
    CASE
        WHEN s.AccountCodeType = '8'   THEN 'South Africa'
        WHEN s.AccountCodeType = '9'   THEN 'Australia'
        WHEN s.AccountCodeType = '1'   THEN 'New Zealand'
        WHEN s.AccountCodeType = '177'
          OR (s.AccountCodeType = '2' AND s.Country = 'GBR')  THEN 'United Kingdom'
        WHEN s.AccountCodeType = '202'
          OR (s.AccountCodeType = '2' AND s.Country = '102') THEN 'Ireland'
        WHEN s.AccountCodeType = '3'   THEN 'Canada'
        WHEN s.AccountCodeType = '277' THEN 'Philippines'
        WHEN s.AccountCodeType = '298' THEN 'Singapore'
        WHEN s.AccountCodeType = '4'   THEN 'United States'
        WHEN s.AccountCodeType = '11'  THEN s.country  -- Swift
        ELSE 'Other'
    END AS InternationalVerification,
    CASE
        WHEN s.VerifiedDate IS NOT NULL THEN 'VerifiedDate'
        ELSE 'CreatedAt'
    END AS VerifiedDate_Source,
    CASE
        WHEN s.VerifiedDate IS NOT NULL THEN 1 ELSE 0
    END AS VerifiedDate_IsPrimary,
    CASE 
    WHEN c.DateCreated IS NOT NULL 
     AND (COALESCE(s.VerifiedDate, s.CreatedAt) IS NULL 
          OR c.DateCreated > COALESCE(s.VerifiedDate, s.CreatedAt))
    THEN c.DateCreated
    ELSE COALESCE(s.VerifiedDate, s.CreatedAt)
END AS Verification_estimate_date
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
    spm.country AS SupplierPaymentMethodsCounty
FROM [EFTSURE_DEV].[dbo].[SUPPLIERS] AS s
LEFT JOIN [PORTAL_PROD].[dbo].[CustomerOnboardings] AS c
    ON s.publicId = c.EmailVerificationPublicId
LEFT JOIN [PORTAL_PROD].[dbo].[SupplierPaymentMethods] AS spm
    ON c.PaymentMethod_Id = spm.Id
LEFT JOIN [EFTSURE_DEV].[dbo].[WHITELIST] w
    ON s.accountKey = w.accountKey
WHERE (c.DateCreated >= '2025-01-01'
   OR  COALESCE(s.VerifiedDate, s.CreatedAt) >= '2025-01-01')
    -- Anti-join: exclude test customers
    AND NOT EXISTS (
        SELECT 1
        FROM [EFTSURE_DEV].[dbo].[customers] AS cu
        WHERE cu.id = s.customerId
          AND (
                cu.groupId = '12'
            OR cu.companyName LIKE '%healthcheck%'
            OR cu.companyName LIKE 'Test%'
            OR cu.companyName LIKE '% Test%'
            OR ISNULL(cu.custInactive, 0) <> 0
          )
    )
    -- Anti-join: exclude test users on that customer
    AND NOT EXISTS (
        SELECT 1
        FROM [EFTSURE_DEV].[dbo].[users] AS u
        WHERE u.customer = s.customerId
          AND (
                u.email LIKE '%@eftsure.com.au'
            OR u.email = 'markc@eteam.com.au'
          )
    );