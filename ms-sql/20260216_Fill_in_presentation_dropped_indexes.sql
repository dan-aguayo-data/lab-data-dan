-- ----------------------------------------------------------------------------
-- Get Index Stats to evaluate
-- ----------------------------------------------------------------------------


-- STEP 1. Materialize the stats (90 seconds)
SELECT object_id, index_id, user_seeks, user_scans, user_lookups, user_updates
INTO #usage_stats
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
    AND object_id = OBJECT_ID('Suppliers');

-- Get days tracked (once)
DECLARE @days INT;
SELECT @days = DATEDIFF(DAY, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info;


-- STEP 2. Writes saved per index &  Summary of YOUR selected indexes - Edit this list with indexes YOU decide to drop

SELECT -- Writes saved per inde
    i.name AS index_name,
    ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0) AS total_reads,
    ISNULL(s.user_updates, 0) AS total_writes,
    ISNULL(s.user_updates, 0) / NULLIF(@days, 0) AS writes_per_day
FROM sys.indexes i
LEFT JOIN #usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.name IN (
        -- =====================================================
        -- ADD YOUR INDEX NAMES HERE
        -- =====================================================
        '_dta_index_Suppliers_8_1301579675__K1_32'
        -- =====================================================
    )
ORDER BY total_writes DESC;

-- Cleanup

DROP TABLE #usage_stats;



-- ----------------------------------------------------------------------------
-- Top 5 Slowest Queries 
-- ----------------------------------------------------------------------------


SELECT TOP 5
    qs.execution_count,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000000.0 AS avg_seconds,
    qs.total_logical_reads / NULLIF(qs.execution_count, 0) AS avg_reads,
    SUBSTRING(qt.text, 1, 150) AS query_preview,
    qt.text AS full_query,
    qs.query_hash
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%Suppliers%'
    AND qt.text NOT LIKE '%sys.%'
      --  AND qs.creation_time >= DATEADD(DAY, -30, GETDATE())  -- Query after improvement date
ORDER BY avg_seconds DESC;




-- ----------------------------------------------------------------------------
-- OTHER QUERIES 
-- ----------------------------------------------------------------------------


--- INSERT/UPDATE Query Performance Baseline  -- it takes less than 5 secs to execute

SELECT 
    COUNT(*) AS write_query_count,
    SUM(qs.execution_count) AS total_executions,
    AVG(qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000000.0) AS avg_seconds_per_query,
    AVG(qs.total_logical_writes / NULLIF(qs.execution_count, 0)) AS avg_writes_per_query,
    SUM(qs.total_elapsed_time) / 1000000.0 AS total_time_spent_seconds
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%SUPPLIERS%'
    AND (qt.text LIKE '%UPDATE%' OR qt.text LIKE '%INSERT%' OR qt.text LIKE '%DELETE%')
    AND qt.text NOT LIKE '%sys.%'
  --  AND qs.creation_time >= DATEADD(DAY, -30, GETDATE())  -- Query after improvement date
    ;