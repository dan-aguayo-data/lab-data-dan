-----############################################################# -----
-----##### IDENTIFY REDUNANDANT INDEXES AND DROP COMMANDS  ##### -----
-----############################################################# -----


-----##### INDEX COUNT FOR ALL TABLES ##### -----
-----Get an idea of the amount of indexes by table

SELECT 
    OBJECT_SCHEMA_NAME(object_id) AS schema_name,
    OBJECT_NAME(object_id) AS table_name,
    SUM(CASE WHEN type = 1 THEN 1 ELSE 0 END) AS clustered_count,
    SUM(CASE WHEN type = 2 THEN 1 ELSE 0 END) AS nonclustered_count,
    COUNT(*) AS total_indexes
FROM sys.indexes
WHERE object_id > 100  -- exclude system objects
    AND is_hypothetical = 0
    AND OBJECTPROPERTY(object_id, 'IsUserTable') = 1
    AND OBJECT_NAME(object_id) NOT LIKE 'tempsuppliers%'
GROUP BY object_id
ORDER BY nonclustered_count DESC, table_name;


-----##### DAYS OF DATA OF STATS TABLE ==> sys.dm_db_index_usage_stats  ##### -----
-----Get an idea of the amount of stats data you currently have in the database

 SELECT 
    sqlserver_start_time,
    DATEDIFF(DAY, sqlserver_start_time, GETDATE()) AS days_of_data
    FROM sys.dm_os_sys_info;


-----##### INDEX USAGE STATISTICS PER TABLE  ##### -----
-----Notes: This will give you the reads(seeks,scans,lookups) vs writes count (wite_cost)
-----       it is important to run the query in a temp tablein prod as it will take too long otherwise      


-- Step 1: Define tables you want to check 
SELECT object_id, index_id, user_seeks, user_scans, user_lookups, user_updates
INTO #usage_stats
FROM sys.dm_db_index_usage_stats
WHERE database_id = DB_ID()
    AND object_id = OBJECT_ID('SUPPLIERS');


-- Step 2: Snapshot usage stats into temp table (ISOLATION)
  
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
        WHEN (ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) = 0 AND ISNULL(s.user_updates, 0) > 0 THEN 1
        WHEN ISNULL(s.user_updates, 0) = 0 THEN 2
        WHEN CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates < 0.1 THEN 3
        WHEN CAST((ISNULL(s.user_seeks, 0) + ISNULL(s.user_scans, 0) + ISNULL(s.user_lookups, 0)) AS FLOAT) / s.user_updates < 0.5 THEN 4
        ELSE 5
    END,
    s.user_updates DESC;

   
-- Cleanup
    DROP TABLE #usage_stats;


-----##### DROP INDEX COMMAND  ##### -----
-----Notes: Be aware this is a table locking operation for the duration of the drop.    


    DROP INDEX [IX_SUPPLIERS_CUSTOMERID] ON [dbo].[SUPPLIERS];