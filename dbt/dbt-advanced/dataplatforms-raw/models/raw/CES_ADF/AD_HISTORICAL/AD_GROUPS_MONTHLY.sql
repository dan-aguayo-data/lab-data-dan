    
{{
    config(
        enabled = (
            run_started_at.astimezone(modules.pytz.timezone('Australia/Sydney')).strftime('%d') | int == 1
        )
    )
}}
    
    SELECT
        *
    FROM
        {{ ref('LANDING_AD_GROUPS_MONTHLY') }}