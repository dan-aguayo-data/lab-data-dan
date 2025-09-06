{{
    config(
        enabled = run_flag_exclude_all()
    )
}}
SELECT *
FROM {{ ref('LANDING_INCREMENTAL_AG_CONTRACT') }}
