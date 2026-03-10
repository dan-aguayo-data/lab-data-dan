
-- ----------------------------------------------------------------------------
-- A1. Stats Time Window (how long have stats been accumulating?)
-- ----------------------------------------------------------------------------


SELECT 
    sqlserver_start_time AS stats_since,
    DATEDIFF(DAY, sqlserver_start_time, GETDATE()) AS days_of_data,
    DATEDIFF(HOUR, sqlserver_start_time, GETDATE()) AS hours_of_data
FROM sys.dm_os_sys_info;


-- ----------------------------------------------------------------------------
-- A2. Current Index Count  -- subsecond
-- ----------------------------------------------------------------------------


SELECT 
    COUNT(*) AS total_nonclustered_indexes,
    SUM(CASE WHEN i.is_unique = 1 THEN 1 ELSE 0 END) AS unique_indexes,
    SUM(CASE WHEN i.is_unique = 0 THEN 1 ELSE 0 END) AS non_unique_indexes
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.type_desc = 'NONCLUSTERED';


-- ----------------------------------------------------------------------------
-- A3. Total Write Cost (index maintenance overhead)  --- this uses a temp view to isolate stats, it takes 90 seconds to run
-- ----------------------------------------------------------------------------

select * from #usage_stats;
select * from #usage_snapshot;

DECLARE @days INT;
SELECT @days = DATEDIFF(DAY, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info;
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
        'IX_SUPPLIERS_DOSENDDATE',
        'IX_SUPPLIERS_ACCOUNTCODE',
        'IX_SUPPLIERS_TAXNUMBER',
        'IX_SUPPLIERS_ACCOUNTNUMBER_INT',
        '_dta_index_SUPPLIERS_7_891150220__K10_K6_K57_K8_K63_K37_K39_K1_K59_K5_3_4_12_66',
        '_dta_index_SUPPLIERS_7_891150220__K12_K1_K5_K59_K8_K10_K6_K57_K63_K37_K39_3_4_66',
        'IX_SUPPLIERS_cGovCode',
        'IX_SUPPLIERS_LASTREQUESTDATE',
        'IX_SUPPLIERS_SUPPLIERCODE',
        'IX_CustId_TempId'
        -- =====================================================
    )
ORDER BY total_writes DESC;


select i.* from sys.indexes i where i.object_id = OBJECT_ID('SUPPLIERS') ;

-- --##STEP 1. Materialize the stats. 


SELECT user_updates, user_seeks, user_scans, user_lookups
INTO #usage_snapshot
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
    AND object_id = OBJECT_ID('SUPPLIERS');

-- Step 2: Calculate from static temp table
DECLARE @days INT;
SELECT @days = DATEDIFF(DAY, sqlserver_start_time, GETDATE()) FROM sys.dm_os_sys_info;
SELECT 
    SUM(user_updates) AS total_index_writes,
    SUM(user_updates) / NULLIF(@days, 0) AS writes_per_day,
    SUM(user_seeks + user_scans + user_lookups) AS total_index_reads,
    SUM(user_seeks + user_scans + user_lookups) / NULLIF(@days, 0) AS reads_per_day
FROM #usage_snapshot;


--6,044,678

-- Step 4: Cleanup
DROP TABLE #usage_snapshot;


-- ----------------------------------------------------------------------------
-- A4. Write Cost by Indexes TO BE DROPPED (YOU HAVE TO ADD THE INDEXES TO BE DROPPED MANUALLY)
-- ----------------------------------------------------------------------------


--##STEP 1. Materialize the stats.   90 SECONDS


-- STEP 1. Materialize the stats (90 seconds)
SELECT object_id, index_id, user_seeks, user_scans, user_lookups, user_updates
INTO #usage_stats
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
    AND object_id = OBJECT_ID('SUPPLIERS');

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
        'IX_SUPPLIERS_DOSENDDATE',
        'IX_SUPPLIERS_ACCOUNTCODE',
        'IX_SUPPLIERS_TAXNUMBER',
        'IX_SUPPLIERS_ACCOUNTNUMBER_INT',
        '_dta_index_SUPPLIERS_7_891150220__K10_K6_K57_K8_K63_K37_K39_K1_K59_K5_3_4_12_66',
        '_dta_index_SUPPLIERS_7_891150220__K12_K1_K5_K59_K8_K10_K6_K57_K63_K37_K39_3_4_66',
        'IX_SUPPLIERS_cGovCode',
        'IX_SUPPLIERS_LASTREQUESTDATE',
        'IX_SUPPLIERS_SUPPLIERCODE',
        'IX_CustId_TempId'
        -- =====================================================
    )
ORDER BY total_writes DESC;


SELECT   -- Summary of YOUR selected indexes
    COUNT(*) AS indexes_to_drop,
    SUM(ISNULL(s.user_updates, 0)) AS total_writes_saved,
    SUM(ISNULL(s.user_updates, 0)) / NULLIF(@days, 0) AS writes_saved_per_day,
    @days AS over_days
FROM sys.indexes i
LEFT JOIN #usage_stats s ON i.object_id = s.object_id AND i.index_id = s.index_id
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.name IN (
        -- =====================================================
        -- SAME LIST AS ABOVE
        -- =====================================================
        'IX_SUPPLIERS_DOSENDDATE',
        'IX_SUPPLIERS_ACCOUNTCODE',
        'IX_SUPPLIERS_TAXNUMBER',
        'IX_SUPPLIERS_ACCOUNTNUMBER_INT',
        '_dta_index_SUPPLIERS_7_891150220__K10_K6_K57_K8_K63_K37_K39_K1_K59_K5_3_4_12_66',
        '_dta_index_SUPPLIERS_7_891150220__K12_K1_K5_K59_K8_K10_K6_K57_K63_K37_K39_3_4_66',
        'IX_SUPPLIERS_cGovCode',
        'IX_SUPPLIERS_LASTREQUESTDATE',
        'IX_SUPPLIERS_SUPPLIERCODE',
        'IX_CustId_TempId'
  );

-- STEP 4. Cleanup
DROP TABLE #usage_stats;


-- ----------------------------------------------------------------------------
-- A5. INSERT/UPDATE Query Performance Baseline  -- it takes less than 5 secs to execute
-- ----------------------------------------------------------------------------


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


-- ----------------------------------------------------------------------------
-- A6. SELECT Query Performance Baseline   - it takes less than 5 seconds to execute
-- ----------------------------------------------------------------------------


SELECT 
    COUNT(*) AS read_query_count,
    SUM(qs.execution_count) AS total_executions,
    AVG(qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000000.0) AS avg_seconds_per_query,
    AVG(qs.total_logical_reads / NULLIF(qs.execution_count, 0)) AS avg_reads_per_query,
    SUM(qs.total_elapsed_time) / 1000000.0 AS total_time_spent_seconds
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
WHERE qt.text LIKE '%SUPPLIERS%'
    AND qt.text LIKE '%SELECT%'
    AND qt.text NOT LIKE '%INSERT%'
    AND qt.text NOT LIKE '%UPDATE%'
    AND qt.text NOT LIKE '%DELETE%'
    AND qt.text NOT LIKE '%sys.%'
      --  AND qs.creation_time >= DATEADD(DAY, -30, GETDATE())  -- Query after improvement date
    ;



-- ----------------------------------------------------------------------------
-- A7. Top 5 Slowest Queries 
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
WHERE qt.text LIKE '%SUPPLIERS%'
    AND qt.text NOT LIKE '%sys.%'
      --  AND qs.creation_time >= DATEADD(DAY, -30, GETDATE())  -- Query after improvement date
ORDER BY avg_seconds DESC;


-- ----------------------------------------------------------------------------
-- A8. Index Fragmentation Baseline (for remaining indexes)  --90 seconds to run
-- ----------------------------------------------------------------------------


SELECT 
    i.name AS index_name,
    ips.avg_fragmentation_in_percent AS fragmentation_pct,
    ips.page_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN ips.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS action_needed
INTO #frag_baseline
FROM sys.dm_db_index_physical_stats(DB_ID(), OBJECT_ID('SUPPLIERS'), NULL, NULL, 'LIMITED') ips
JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.index_id > 0
    AND ips.page_count > 1000;

SELECT * FROM #frag_baseline ORDER BY fragmentation_pct DESC;

-- Summary
SELECT 
    AVG(fragmentation_pct) AS avg_fragmentation,
    MAX(fragmentation_pct) AS max_fragmentation,
    SUM(CASE WHEN action_needed = 'REBUILD' THEN 1 ELSE 0 END) AS need_rebuild,
    SUM(CASE WHEN action_needed = 'REORGANIZE' THEN 1 ELSE 0 END) AS need_reorganize,
    SUM(CASE WHEN action_needed = 'OK' THEN 1 ELSE 0 END) AS ok_count
FROM #frag_baseline;

DROP TABLE #frag_baseline;
DROP TABLE #usage_stats;


