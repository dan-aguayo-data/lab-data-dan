    SELECT
        *
    FROM
        {{ source('COEX_HSE_RESPONSES', 'FORM_RESPONSES') }}