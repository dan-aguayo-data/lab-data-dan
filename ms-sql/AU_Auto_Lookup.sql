SELECT
    DateCreated,
    Date,
    CustomerOnboarding_Id AS OID,
    Notes,
    CASE
        WHEN Notes LIKE '%(using Bank Link)%' THEN 'Yodlee'
        WHEN Notes LIKE 'Onboarding has passed Auto-Verification (AVS)' THEN 'AVS'
        WHEN Notes LIKE '%Onboarding has been Auto-Verified (AVIO)%' THEN 'AVIO'
        WHEN Notes LIKE '%Onboarding has been Auto-Verified (AVWO)%' THEN 'AVWO'
        ELSE 'Other'
    END AS Onboarding_Auto_Type
FROM [PORTAL_PROD].[dbo].[CustomerOnboardingInteractions] i
JOIN [PORTAL_PROD].[dbo].[CustomerOnboardings] c
    ON i.CustomerOnboarding_Id = c.Id
WHERE (
        Notes LIKE '% Auto-Verified%'
     OR Notes LIKE '%Auto-Accepted%'
     OR Notes LIKE '%(using Bank Link)%'
     OR Notes LIKE '%Onboarding has passed Auto-Verification (AVS)%'
)
AND Date > DateCreated
AND DateCreated > '2025-01-01'