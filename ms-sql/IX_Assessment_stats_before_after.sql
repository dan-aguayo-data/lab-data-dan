

-- time it takes for inserts/updates on suppliers

SELECT 
    qs.creation_time AS stats_since,
    DATEDIFF(HOUR, qs.creation_time, GETDATE()) AS hours_tracked,
    qs.execution_count,
    qs.execution_count / NULLIF(DATEDIFF(HOUR, qs.creation_time, GETDATE()), 0) AS execs_per_hour,
    qs.total_elapsed_time / 1000 AS total_ms,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000.0 AS avg_ms_per_exec,
    qs.total_worker_time / NULLIF(qs.execution_count, 0) / 1000.0 AS avg_cpu_ms_per_exec,
    qs.total_logical_writes / NULLIF(qs.execution_count, 0) AS avg_writes_per_exec,
    SUBSTRING(st.text, 1, 200) AS query_preview
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND (st.text LIKE '%UPDATE%' OR st.text LIKE '%INSERT%' OR st.text LIKE '%DELETE%')
    AND st.text NOT LIKE '%sys.%'
ORDER BY qs.total_elapsed_time DESC;

--Time period: Each row has a different creation_time - that's when the plan was cached. Stats accumulate from that point until now (or until the plan gets evicted/recompiled).



---Amount of Writes on SUPPLIERS Over Time

-- Writes since SQL Server restart
SELECT 
    si.sqlserver_start_time AS stats_since,
    DATEDIFF(DAY, si.sqlserver_start_time, GETDATE()) AS days_tracked,
    SUM(s.user_updates) AS total_writes,
    SUM(s.user_updates) / NULLIF(DATEDIFF(DAY, si.sqlserver_start_time, GETDATE()), 0) AS writes_per_day,
    SUM(s.user_updates) / NULLIF(DATEDIFF(HOUR, si.sqlserver_start_time, GETDATE()), 0) AS writes_per_hour
FROM sys.dm_db_index_usage_stats s
CROSS JOIN sys.dm_os_sys_info si
WHERE s.database_id = DB_ID()
    AND s.object_id = OBJECT_ID('SUPPLIERS')
GROUP BY si.sqlserver_start_time;



--- TOP reads against suppliers

SELECT TOP 20
    qs.execution_count,
    qs.total_logical_reads,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS avg_reads_per_exec,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000.0 AS avg_ms,
    qs.creation_time AS stats_since,
    SUBSTRING(st.text, 1, 300) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND st.text LIKE '%SELECT%'
    AND st.text NOT LIKE '%INSERT%'
    AND st.text NOT LIKE '%UPDATE%'
    AND st.text NOT LIKE '%DELETE%'
    AND st.text NOT LIKE '%sys.%'
ORDER BY qs.total_logical_reads DESC;