
-- Recently executed (last few minutes) - requires Query Store enabled
SELECT TOP 20
    qsqt.query_sql_text,
    qsrs.last_execution_time,
    qsrs.avg_duration / 1000 AS avg_ms,
    qsrs.avg_logical_io_reads,
    qsrs.avg_logical_io_writes
FROM sys.query_store_query_text qsqt
JOIN sys.query_store_query qsq ON qsqt.query_text_id = qsq.query_text_id
JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
JOIN sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
WHERE qsqt.query_sql_text LIKE '%SUPPLIERS%'
ORDER BY qsrs.last_execution_time DESC;



--  queries hitting SUPPLIERS with full text and execution count, from cached execution plans
SELECT TOP 20
    qs.execution_count,
        qs.creation_time AS plan_cached_since,

    qs.total_elapsed_time / 1000 AS total_ms,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000 AS avg_ms,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS avg_reads,
    qs.total_logical_writes / NULLIF(qs.execution_count, 0) AS avg_writes,
    CASE 
        WHEN qs.total_logical_writes > qs.total_logical_reads THEN 'WRITE-HEAVY'
        ELSE 'READ-HEAVY'
    END AS query_type,
    SUBSTRING(st.text, 1, 500) AS query_text_preview,
    st.text AS full_query_text,
    qs.query_hash
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND st.text NOT LIKE '%sys.%'  -- exclude our diagnostic queries
ORDER BY qs.execution_count DESC;

--Find a specific read query (SELECT):
SELECT TOP 10
    qs.execution_count,
    qs.total_logical_reads,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS reads_per_exec,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000 AS avg_ms,
    st.text AS full_query
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '% SETTINGSCUSTOMER.settingId = SETTINGS.Id%'
    AND st.text LIKE '%SELECT%'
    AND st.text NOT LIKE '%UPDATE%'
    AND st.text NOT LIKE '%INSERT%'
    AND st.text NOT LIKE '%sys.%'
ORDER BY qs.execution_count DESC;





--Find a specific write query (INSERT/UPDATE/DELETE):

SELECT TOP 10
    qs.execution_count,
    qs.total_logical_writes,
    qs.total_logical_writes / NULLIF(qs.execution_count, 0) AS writes_per_exec,
    st.text AS full_query
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND (st.text LIKE '%UPDATE%' OR st.text LIKE '%INSERT%' OR st.text LIKE '%DELETE%')
    AND st.text NOT LIKE '%sys.%'
ORDER BY qs.total_logical_writes DESC;


--Find your most frequent write queries on SUPPLIERS:

SELECT 
    qs.execution_count,
    qs.creation_time AS plan_cached_since,
    DATEDIFF(HOUR, qs.creation_time, GETDATE()) AS hours_in_cache,
    qs.execution_count / NULLIF(DATEDIFF(HOUR, qs.creation_time, GETDATE()), 0) AS execs_per_hour,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000.0 AS avg_ms,
    qs.total_logical_writes / NULLIF(qs.execution_count, 0) AS avg_writes_per_exec,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS avg_reads_per_exec,
    qs.query_hash,
    SUBSTRING(st.text, 1, 150) AS query_preview
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND (st.text LIKE '%UPDATE%' OR st.text LIKE '%INSERT%' OR st.text LIKE '%DELETE%')
    AND st.text NOT LIKE '%sys.%'
ORDER BY qs.execution_count DESC;




-- snapshot for inserts


SELECT 
    GETDATE() AS snapshot_time,
    'BEFORE' AS phase,
    COUNT(*) AS query_count,
    SUM(qs.execution_count) AS total_executions,
    AVG(qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000.0) AS avg_ms,
    AVG(qs.total_logical_writes / NULLIF(qs.execution_count, 0)) AS avg_writes_per_exec
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND (st.text LIKE '%UPDATE%' OR st.text LIKE '%INSERT%')
    AND st.text NOT LIKE '%sys.%';