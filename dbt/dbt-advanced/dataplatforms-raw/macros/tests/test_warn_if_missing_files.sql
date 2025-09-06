{% test test_warn_if_missing_files(model) %}

    {{ config(severity = 'warn') }}

    with last_24hrs AS (
        SELECT split_part(file_name,'/',1) as file_stem, count(1)
        FROM {{ model }}
        where landed_datetime >= dateadd(hours, -24, current_timestamp())
        group by 1
    )
    , last_hour AS (
        SELECT split_part(file_name,'/',1) as file_stem, count(1)
        FROM {{ model }}
        where landed_datetime >= dateadd(hours, -1, current_timestamp())
        group by 1
    )
    SELECT file_stem
    FROM last_24hrs
    MINUS
    SELECT file_stem
    FROM last_hour

{% endtest %}