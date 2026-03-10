-- Step 1: Define tables you want to check (modify this list)
DECLARE @tables TABLE (object_id INT, table_name NVARCHAR(128));
INSERT INTO @tables VALUES 
    (OBJECT_ID('SUPPLIERS'), 'SUPPLIERS');

-- Step 2: Snapshot fragmentation for those tables only
SELECT 
    t.table_name,
    ips.object_id,
    ips.index_id,
    ips.avg_fragmentation_in_percent,
    ips.page_count
INTO #frag_stats
FROM @tables t
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), t.object_id, NULL, NULL, 'LIMITED') ips
WHERE ips.index_id > 0
    AND ips.page_count > 1000;

-- Step 3: Join for details
SELECT 
    f.table_name,
    i.name AS index_name,
    f.avg_fragmentation_in_percent,
    f.page_count,
    CASE 
        WHEN f.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN f.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS recommended_action
FROM #frag_stats f
JOIN sys.indexes i ON f.object_id = i.object_id AND f.index_id = i.index_id
WHERE f.avg_fragmentation_in_percent > 10
ORDER BY f.page_count DESC;

DROP TABLE #frag_stats;