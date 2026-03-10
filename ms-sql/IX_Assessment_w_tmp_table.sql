-- Step 1: Snapshot the DMV into temp table
SELECT object_id, index_id, user_seeks, user_scans, user_lookups, user_updates
INTO #usage_stats
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
    AND object_id = OBJECT_ID('SUPPLIERS');

-- Step 2: Join and calculate
SELECT 
    OBJECT_NAME(i.object_id) AS table_name,
    i.name AS index_name,
    i.type_desc,
    s.user_seeks,
    s.user_scans,
    s.user_lookups,
    (ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS total_reads,
    s.user_updates AS write_cost,
    CASE 
        WHEN ISNULL(s.user_updates, 0) = 0 THEN NULL
        ELSE CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates 
    END AS read_to_write_ratio,
    CASE 
        WHEN (ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) = 0 AND ISNULL(s.user_updates, 0) > 0 
            THEN 'DROP - Never read, pure write cost'
        WHEN ISNULL(s.user_updates, 0) = 0 
            THEN 'ASSESS - No activity (new index or stats reset?)'
        WHEN CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates < 0.1 
            THEN 'ASSESS - Write heavy, questionable value'
        WHEN CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates < 0.5 
            THEN 'REVIEW - Low read ratio, consider removing'
        WHEN CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates <= 2 
            THEN 'KEEP - Balanced usage'
        ELSE 'KEEP - Read heavy, valuable index'
    END AS recommendation
FROM sys.indexes i
LEFT JOIN #usage_stats s 
    ON i.object_id = s.object_id 
    AND i.index_id = s.index_id
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.type_desc = 'NONCLUSTERED'
ORDER BY 
    CASE 
        WHEN ISNULL(s.user_updates, 0) = 0 THEN NULL
        ELSE CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates 
    END  DESC;

-- Step 3: Cleanup
DROP TABLE #usage_stats;