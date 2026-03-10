-- Step 1: What is blocking the log from cycling?
SELECT name, log_reuse_wait_desc 
FROM sys.databases 
WHERE name = 'tempdb';



-- Step 2: Any open transactions?
SELECT 
    s.session_id,
    s.login_name,
    s.program_name,
    s.open_transaction_count,
    t.transaction_begin_time,
    DATEDIFF(MINUTE, t.transaction_begin_time, GETDATE()) AS open_minutes
FROM sys.dm_tran_session_transactions st
JOIN sys.dm_tran_active_transactions t ON st.transaction_id = t.transaction_id
JOIN sys.dm_exec_sessions s ON st.session_id = s.session_id
ORDER BY t.transaction_begin_time ASC;


USE tempdb;
GO

-- Count your VLFs - this is key
--DBCC LOGINFO;


-- Check if active VLFs are small portion of total
SELECT 
  *
FROM sys.dm_db_log_space_usage;

-- You can check current growth settings at least
SELECT 
    name,
    size * 8.0 / 1024          AS current_size_MB,
    growth * 8.0 / 1024        AS growth_increment_MB,
    is_percent_growth
FROM sys.master_files
WHERE database_id = 2  -- tempdb
AND type = 1;          -- log file only


-- See all tempdb files
SELECT 
    name,
    physical_name,
    size * 8.0 / 1024       AS current_size_MB,
    growth,
    is_percent_growth,
    max_size
FROM sys.master_files
WHERE database_id = 2;


-- What sessions are actively using tempdb log space RIGHT NOW
SELECT 
    s.session_id,
    s.login_name,
    s.program_name,
    s.host_name,
    tsu.user_objects_alloc_page_count * 8.0 / 1024 AS user_objects_mb,
    tsu.internal_objects_alloc_page_count * 8.0 / 1024 AS internal_objects_mb,
    tsu.user_objects_dealloc_page_count * 8.0 / 1024 AS user_objects_dealloc_mb,
    tsu.internal_objects_dealloc_page_count * 8.0 / 1024 AS internal_objects_dealloc_mb
FROM sys.dm_db_session_space_usage tsu
JOIN sys.dm_exec_sessions s ON tsu.session_id = s.session_id
WHERE (tsu.user_objects_alloc_page_count > 0 
   OR tsu.internal_objects_alloc_page_count > 0)
ORDER BY (tsu.user_objects_alloc_page_count + tsu.internal_objects_alloc_page_count) DESC;

