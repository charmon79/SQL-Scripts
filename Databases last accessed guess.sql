
CREATE TABLE #Results (
    DatabaseName sysname
,   LastUpdate datetime
,   LastRead datetime
);

INSERT #Results
EXEC sp_Msforeachdb
N'USE [?];
SELECT
    DB_NAME() AS DatabaseName
,   MAX(ius.last_user_update) AS LastUpdate
,   MAX(COALESCE(ius.last_user_seek, ius.last_user_scan, ius.last_user_lookup)) AS LastRead
FROM sys.tables AS t
JOIN sys.dm_db_index_usage_stats AS ius ON ius.database_id = db_id() AND ius.object_id = t.object_id;'

SELECT *
FROM #Results;