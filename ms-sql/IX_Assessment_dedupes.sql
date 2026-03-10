
--This shows key columns in order - indexes with the same leading columns are likely redundant.
SELECT 
    i.name AS index_name,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns,
    STRING_AGG(CASE WHEN ic.is_included_column = 1 THEN c.name END, ', ') 
        WITHIN GROUP (ORDER BY ic.key_ordinal) AS included_columns,
    i.is_unique
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('SUPPLIERS')
    AND i.type_desc = 'NONCLUSTERED'
GROUP BY i.name, i.is_unique
ORDER BY key_columns, index_name;


WITH index_cols AS (
    SELECT 
        i.name AS index_name,
        i.index_id,
        c.name AS first_column,
        (SELECT STRING_AGG(c2.name, ',') WITHIN GROUP (ORDER BY ic2.key_ordinal)
         FROM sys.index_columns ic2
         JOIN sys.columns c2 ON ic2.object_id = c2.object_id AND ic2.column_id = c2.column_id
         WHERE ic2.object_id = i.object_id AND ic2.index_id = i.index_id AND ic2.is_included_column = 0
        ) AS all_key_columns
    FROM sys.indexes i
    JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id AND ic.key_ordinal = 1
    JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
    WHERE i.object_id = OBJECT_ID('SUPPLIERS')
        AND i.type_desc = 'NONCLUSTERED'
)
SELECT 
    first_column,
    COUNT(*) AS index_count,
    STRING_AGG(index_name, CHAR(10)) AS indexes_sharing_first_column
FROM index_cols
GROUP BY first_column
HAVING COUNT(*) > 1
ORDER BY COUNT(*) DESC;



Summary
PhaseActionIndexes DroppedWrite Ops SavedPhase 1Zero reads8~170MDuplicatesIdentical1~22MPhase 2< 100k reads24~500MTotal33~690M writes



;
-- FIND WHICH QUERIES ARE USING THE INDEX


SELECT 
    SUBSTRING(st.text, 1, 300) AS query_text,
    ix.name AS index_name,
    ix_usage.user_seeks,
    ix_usage.user_scans
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
JOIN sys.indexes ix ON ix.object_id = OBJECT_ID('SUPPLIERS')
JOIN sys.dm_db_index_usage_stats ix_usage 
    ON ix.object_id = ix_usage.object_id 
    AND ix.index_id = ix_usage.index_id
WHERE st.text LIKE '%SUPPLIERS%'
    AND ix.name = 'IX_SUPPLIERS_CUSTID_ISINACTIVE'  -- check one at a time
    AND CAST(qp.query_plan AS NVARCHAR(MAX)) LIKE '%CUSTID_ISINACTIVE%';


;


-- Find queries and their plans that reference SUPPLIERS
SELECT 
    SUBSTRING(st.text, 1, 500) AS query_text,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE st.text LIKE '%SUPPLIERS%'
    AND st.text LIKE '%customerId%'
    AND st.text LIKE '%isInactive%';