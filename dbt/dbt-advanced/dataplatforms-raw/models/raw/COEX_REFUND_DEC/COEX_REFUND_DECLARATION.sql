    SELECT
        *
    FROM
        {{ source('COEX_REFUND_DEC', '_01_REFUND_DECLARATIONS_LOG_SHEET') }}