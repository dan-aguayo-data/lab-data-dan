-- When did SQL Server last start?
SELECT 
    sqlserver_start_time,
    DATEDIFF(DAY, sqlserver_start_time, GETDATE()) AS days_of_stats
FROM sys.dm_os_sys_info;