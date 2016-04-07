USE master;

SELECT *
FROM sys.dm_db_missing_index_details AS mi
LEFT JOIN sys.dm_db_missing_index_groups AS mig ON mig.index_handle = mi.index_handle
LEFT JOIN sys.dm_db_missing_index_group_stats AS migs ON migs.group_handle = mig.index_group_handle
WHERE mi.database_id = DB_ID('xcelweb_prod')
ORDER BY migs.avg_user_impact desc