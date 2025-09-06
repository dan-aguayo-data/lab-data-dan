{% test test_warn_if_copy_errors(model) %}

    {{ config(severity = 'warn') }}

    WITH source AS (
        select split_part(FILE_NAME,'/',1) AS FILE_NAME, 
            LAST_LOAD_TIME, 
            PIPE_RECEIVED_TIME, 
            ERROR_COUNT
    from table(information_schema.copy_history(
        table_name=>'LANDING.SNOWPIPE_PROD.CES_MSCM_PROD', 
        start_time=> dateadd(hours, -1, current_timestamp)
            )
        )
    )
    , result AS (
        select s.* from source s
        QUALIFY row_number() OVER ( PARTITION BY s.FILE_NAME ORDER BY s.LAST_LOAD_TIME DESC ) = 1
    )

    select file_name
    FROM result
    where error_count > 0

{% endtest %}