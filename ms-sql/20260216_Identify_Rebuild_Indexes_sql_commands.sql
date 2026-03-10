-----############################################################# -----
-----##### IDENTIFY FRAGMENTED INDEXES AND REBUILD COMMANDS  ##### -----
-----############################################################# -----


-----##### IDENTIFY FRAGMENTED INDEXES BY TABLE ##### -----
-----Notes: This is the safe way to run this in production. 
-----       It will take around 90 seconds. Without it, it can go on for over 10 min. 


-- Step 1: Define tables you want to check (add/remove as needed)
DECLARE @tables TABLE (object_id INT, table_name NVARCHAR(128));
INSERT INTO @tables VALUES 
    (OBJECT_ID('Suppliers'), 'Suppliers'),
    (OBJECT_ID('CustomerOnboardings'), 'CustomerOnboardings');  -- Add more tables here
-- Step 2: Snapshot fragmentation stats into temp table (ISOLATION)
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
-- Step 3: Build maintenance commands from snapshot
SELECT 
    f.table_name,
    i.name AS index_name,
    f.avg_fragmentation_in_percent,
    f.page_count,
    CASE 
        WHEN f.avg_fragmentation_in_percent > 30 THEN 'REBUILD'
        WHEN f.avg_fragmentation_in_percent > 10 THEN 'REORGANIZE'
        ELSE 'OK'
    END AS recommended_action,
    CASE 
        WHEN f.avg_fragmentation_in_percent > 30 
            THEN 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(f.object_id) + '].[' + f.table_name + '] REBUILD WITH (ONLINE = ON);'
        ELSE 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(f.object_id) + '].[' + f.table_name + '] REORGANIZE;'
    END AS maintenance_command
FROM #frag_stats f
INNER JOIN sys.indexes i ON f.object_id = i.object_id AND f.index_id = i.index_id
WHERE f.avg_fragmentation_in_percent > 10
ORDER BY f.page_count DESC;
-- Cleanup
DROP TABLE #frag_stats;


-----##### REORGANIZE INDEX COMMAND ##### -----

ALTER INDEX [PK_dbo.Suppliers] ON [dbo].[Suppliers] REORGANIZE;


-----##### REBUILD INDEX COMMAND  ##### -----
-----Notes: We have to use ONLINE= ON, to avoid downtime on hte database, without it we would lock the tables.
 ALTER INDEX [IX_SUPPLIERS_xyz] ON dbo.SUPPLIERS REBUILD WITH (FILLFACTOR = 80, ONLINE = ON);


-----##### COMMAND TO REBUILD ALL INDEXES INSIDE A TABLE  ##### -----

 DECLARE @StartTime DATETIME = GETDATE();

ALTER INDEX ALL ON dbo.SUPPLIERS_Maintained REBUILD
WITH (
    FILLFACTOR = 80,              -- Leave 20% free space for future updates
    PAD_INDEX = ON,               -- Apply fillfactor to intermediate index pages
    SORT_IN_TEMPDB = ON,          -- Faster rebuild, uses tempdb
    STATISTICS_NORECOMPUTE = OFF, -- Keep statistics auto-update enabled
    ONLINE = OFF,                 -- Set to ON if you have Enterprise Edition
    MAXDOP = 0                    -- Use all available processors (or set to specific number)
);



-----##### COMMAND TO GENERAGE MAINENTANCE COMMANDS TO USE (FILTERING BY TABLE) #####-----
SELECT 
    OBJECT_SCHEMA_NAME(ips.object_id) AS schema_name,
    OBJECT_NAME(ips.object_id) AS table_name,
    i.name AS index_name,
    ips.avg_fragmentation_in_percent,
    ips.page_count,
    CASE 
        WHEN ips.avg_fragmentation_in_percent > 30 
            THEN 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(ips.object_id) + '].[' + OBJECT_NAME(ips.object_id) + '] REBUILD WITH (ONLINE = ON);'
        ELSE 'ALTER INDEX [' + i.name + '] ON [' + OBJECT_SCHEMA_NAME(ips.object_id) + '].[' + OBJECT_NAME(ips.object_id) + '] REORGANIZE;'
    END AS maintenance_command
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i 
    ON ips.object_id = i.object_id 
    AND ips.index_id = i.index_id
WHERE ips.index_id > 0
    AND ips.page_count > 1000
    AND ips.avg_fragmentation_in_percent > 10
    AND ips.object_id = (OBJECT_ID('Suppliers'))
ORDER BY ips.page_count DESC;