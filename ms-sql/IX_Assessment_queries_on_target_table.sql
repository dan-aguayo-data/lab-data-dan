SELECT blocking_session_id, wait_type, wait_time, session_id
FROM sys.dm_exec_requests
WHERE session_id = @@SPID;

SELECT 
    'Total rows in DMV' AS metric,
    COUNT(*) AS cnt
FROM sys.dm_db_index_usage_stats

UNION ALL

SELECT 
    'Rows for current DB',
    COUNT(*)
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()

UNION ALL

SELECT 
    'Number of databases',
    COUNT(*)
FROM sys.databases;


SELECT 
    r.session_id,
    r.wait_type,
    r.wait_time,
    r.wait_resource,
    r.blocking_session_id,
    r.status
FROM sys.dm_exec_requests r
WHERE r.session_id = @@SPID;


-- Current waits across the server
SELECT TOP 10
    wait_type,
    wait_time_ms / 1000.0 AS wait_sec,
    waiting_tasks_count
FROM sys.dm_os_wait_stats
WHERE wait_type NOT LIKE '%SLEEP%'
    AND wait_type NOT LIKE '%IDLE%'
    AND wait_type NOT LIKE '%QUEUE%'
ORDER BY wait_time_ms DESC;




SELECT COUNT(*) FROM sys.dm_db_index_usage_stats -- WHERE object_id = OBJECT_ID('SUPPLIERS');



-- Queries hitting suppliers table
SELECT 
    r.session_id,
    r.status,
    r.wait_type,
    r.wait_time,
    r.cpu_time,
    r.total_elapsed_time / 1000 AS elapsed_seconds,
    r.reads,
    r.writes,
    r.logical_reads,
    SUBSTRING(t.text, 1, 200) AS query_text
FROM sys.dm_exec_requests r
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id != @@SPID
    AND t.text LIKE '%SUPPLIERS%';





