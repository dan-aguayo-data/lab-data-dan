SELECT --TOP 50
    qs.execution_count,
    qs.creation_time AS stats_since,
    DATEDIFF(HOUR, qs.creation_time, GETDATE()) AS hours_tracked,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000000.0 AS avg_seconds,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS avg_reads,
    qs.total_logical_reads AS total_reads,
    SUBSTRING(qt.text, 1, 300) AS query_preview
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%SUPPLIERS%'
    AND qt.text NOT LIKE '%sys.%'
    AND qt.text NOT LIKE '%dm_exec%'
ORDER BY avg_reads DESC;



