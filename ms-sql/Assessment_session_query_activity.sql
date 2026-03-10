

---###BASIC ASSESSMENT##-----

---Requests to the db being blocked
SELECT * 
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;
GO



--###SHOW ALL SYSTEM PROCESSES AND WHO IS RUNNING THEM###
SP_Who2 'ACTIVE'

--###KILL SPID (PROCESS) ###

--kill 8

;

---AN EXTENSION OF THE ABOVE, SEE ALL ACTIVE SESSIONS AND STATS — Runtime, CPU & I/O
SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time                                          AS cpu_ms,
    s.total_elapsed_time / 1000                         AS elapsed_sec,
    s.reads                                             AS logical_reads,
    s.writes,
    s.logical_reads,
    s.memory_usage * 8                                  AS memory_kb,
    r.command,
    r.wait_type,
    r.wait_time / 1000                                  AS wait_sec,
    r.blocking_session_id,
    r.percent_complete,
    DB_NAME(r.database_id)                              AS database_name,
    SUBSTRING(t.text, (r.statement_start_offset / 2) + 1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE r.statement_end_offset
          END - r.statement_start_offset) / 2) + 1)    AS current_statement,
    t.text                                              AS full_batch
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE s.is_user_process = 1
  AND s.status != 'sleeping'          -- remove this line to see ALL sessions
ORDER BY s.cpu_time DESC;



---#### WAIT TIME ### ---

-- CURRENT WAITS ACCROSS ALL REQUESTS
SELECT
    r.session_id,
    r.wait_type,
    r.wait_time / 1000                                  AS wait_sec,
    r.last_wait_type,
    r.blocking_session_id,
    s.login_name,
    s.host_name,
    DB_NAME(r.database_id)                              AS database_name,
    SUBSTRING(t.text, (r.statement_start_offset / 2) + 1,
        ((CASE r.statement_end_offset
            WHEN -1 THEN DATALENGTH(t.text)
            ELSE r.statement_end_offset
          END - r.statement_start_offset) / 2) + 1)    AS current_statement
FROM sys.dm_exec_requests r
JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE s.is_user_process = 1
  AND r.wait_type IS NOT NULL
ORDER BY r.wait_time DESC;




-- What wait types are dominating the server since last restart  (this can be misleading as sometimes last restart was several months ago ! )
SELECT TOP 20
    wait_type,
    waiting_tasks_count,
    wait_time_ms / 1000                                 AS total_wait_sec,
    max_wait_time_ms / 1000                             AS max_wait_sec,
    (wait_time_ms - signal_wait_time_ms) / 1000         AS resource_wait_sec,
    signal_wait_time_ms / 1000                          AS signal_wait_sec,
    CAST(100.0 * wait_time_ms / SUM(wait_time_ms) OVER () AS DECIMAL(5,2)) AS pct
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN (  -- filter out benign background waits
    'SLEEP_TASK','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_AUTO_EVENT',
    'DISPATCHER_QUEUE_SEMAPHORE','FT_IFTS_SCHEDULER_IDLE_WAIT',
    'HADR_WORK_QUEUE','LAZYWRITER_SLEEP','LOGMGR_QUEUE',
    'ONDEMAND_TASK_QUEUE','REQUEST_FOR_DEADLOCK_SEARCH','RESOURCE_QUEUE',
    'SERVER_IDLE_CHECK','SLEEP_DBSTARTUP','SLEEP_DBTASK',
    'SLEEP_TEMPDBSTARTUP','SNI_HTTP_ACCEPT','SP_SERVER_DIAGNOSTICS_SLEEP',
    'SQLTRACE_BUFFER_FLUSH','SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
    'WAIT_XTP_OFFLINE_CKPT_NEW_LOG','WAITFOR','XE_DISPATCHER_WAIT',
    'XE_TIMER_EVENT','BROKER_EVENTHANDLER','CHECKPOINT_QUEUE',
    'DBMIRROR_EVENTS_QUEUE','SQLTRACE_WAIT_ENTRIES'
)
ORDER BY wait_time_ms DESC;



--Blocking chain -- who is blocking who 


WITH blocking AS (
    SELECT
        r.session_id,
        r.blocking_session_id,
        r.wait_type,
        r.wait_time / 1000                              AS wait_sec,
        s.login_name,
        s.host_name,
        DB_NAME(r.database_id)                          AS database_name,
        SUBSTRING(t.text, (r.statement_start_offset / 2) + 1,
            ((CASE r.statement_end_offset
                WHEN -1 THEN DATALENGTH(t.text)
                ELSE r.statement_end_offset
              END - r.statement_start_offset) / 2) + 1) AS current_statement,
        t.text                                          AS full_batch
    FROM sys.dm_exec_requests r
    JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
    WHERE r.blocking_session_id > 0
)
SELECT
    b.*,
    -- also show what the HEAD blocker is running
    bt.text                                             AS blocker_batch
FROM blocking b
OUTER APPLY (
    SELECT t2.text
    FROM sys.dm_exec_requests r2
    OUTER APPLY sys.dm_exec_sql_text(r2.sql_handle) t2
    WHERE r2.session_id = b.blocking_session_id
    UNION ALL
    -- head blocker may be sleeping (holding a lock but not actively running)
    SELECT t3.text
    FROM sys.dm_exec_connections c
    OUTER APPLY sys.dm_exec_sql_text(c.most_recent_sql_handle) t3
    WHERE c.session_id = b.blocking_session_id
) bt
ORDER BY b.wait_sec DESC;


-- Queries that have hammered CPU since plan cache was last populated  (This can be misleading as it depends of what is in cache, it works best to know what was executed recently ONLY PAST )
SELECT TOP 20
    qs.total_worker_time / 1000                         AS total_cpu_ms,
    qs.execution_count,
    qs.total_worker_time / qs.execution_count / 1000    AS avg_cpu_ms,
    qs.total_elapsed_time / qs.execution_count / 1000   AS avg_elapsed_ms,
    qs.total_logical_reads / qs.execution_count         AS avg_logical_reads,
    qs.creation_time                                    AS plan_compiled_at,
    DB_NAME(qt.dbid)                                    AS database_name,
    SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1,
        ((CASE qs.statement_end_offset
            WHEN -1 THEN DATALENGTH(qt.text)
            ELSE qs.statement_end_offset
          END - qs.statement_start_offset) / 2) + 1)   AS statement_text
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) qt
ORDER BY qs.total_worker_time DESC;






