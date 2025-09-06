    SELECT
        *
    FROM
        {{ source('COEX_GOOGLE', 'CC_GA_EVENTS') }}