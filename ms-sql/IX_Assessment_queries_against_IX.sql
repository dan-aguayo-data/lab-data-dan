---  Index Recently Used + Queries Against It
--Check when index was last used:

SELECT 
    i.name AS index_name,
    s.last_user_seek,
    s.last_user_scan,
    s.last_user_lookup,
    s.last_user_update,
    -- Most recent activity of any type
    (SELECT MAX(v) FROM (VALUES (s.last_user_seek), (s.last_user_scan), (s.last_user_lookup), (s.last_user_update)) AS T(v)) AS last_used,
    DATEDIFF(MINUTE, 
        (SELECT MAX(v) FROM (VALUES (s.last_user_seek), (s.last_user_scan), (s.last_user_lookup), (s.last_user_update)) AS T(v)),
        GETDATE()
    ) AS minutes_since_last_use
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats s 
    ON i.object_id = s.object_id 
    AND i.index_id = s.index_id
    AND s.database_id = DB_ID()
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.type_desc = 'NONCLUSTERED'
ORDER BY last_used DESC;

--Find queries that might be using a specific index (searches query text for index hints or related columns):


-- Replace 'IX_SUPPLIERS_ACCOUNTKEY' with your index name
DECLARE @index_name NVARCHAR(128) = 'IX_SUPPLIERS_ACCOUNTKEY';

-- Get the columns in this index
SELECT @index_name AS checking_index;

SELECT 
    c.name AS column_name,
    ic.key_ordinal,
    ic.is_included_column
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.name = @index_name
ORDER BY ic.key_ordinal;

-- Find queries using those columns
SELECT 
    qs.execution_count,
    qs.total_elapsed_time / NULLIF(qs.execution_count, 0) / 1000.0 AS avg_ms,
    SUBSTRING(st.text, 1, 300) AS query_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
WHERE st.text LIKE '%SUPPLIERS%'
    AND st.text LIKE '%accountKey%'  -- Change to match index columns
    AND st.text NOT LIKE '%sys.%'
ORDER BY qs.execution_count DESC;