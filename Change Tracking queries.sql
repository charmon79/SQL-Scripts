/*
    Is cleanup enabled, and is there a retention period set?
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

GO
SELECT
db.name AS change_tracking_db,
is_auto_cleanup_on,
retention_period,
retention_period_units_desc
FROM sys.change_tracking_databases ct
JOIN sys.databases db on
ct.database_id=db.database_id;
GO

/*
    What tables are using Change Tracking?
*/

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
SELECT sc.name as tracked_schema_name,
so.name as tracked_table_name,
ctt.is_track_columns_updated_on,
ctt.begin_version /*when CT was enabled, or table was truncated */,
ctt.min_valid_version /*syncing applications should only expect data on or after this version */ ,
ctt.cleanup_version /*cleanup may have removed data up to this version */
FROM sys.change_tracking_tables AS ctt
JOIN sys.objects AS so on
ctt.[object_id]=so.[object_id]
JOIN sys.schemas AS sc on
so.schema_id=sc.schema_id;
GO

/*
    How many transactions against tracked tables in retention period?
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
SELECT
count(*) AS number_commits,
MIN(commit_time) AS minimum_commit_time,
MAX(commit_time) AS maximum_commit_time
FROM sys.dm_tran_commit_table
GO

/*
    How big are the Change Tracking internal tables?
*/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
GO
select sct1.name as CT_schema,
sot1.name as CT_table,
ps1.row_count as CT_rows,
ps1.reserved_page_count*8./1024. as CT_reserved_MB,
sct2.name as tracked_schema,
sot2.name as tracked_name,
ps2.row_count as tracked_rows,
ps2.reserved_page_count*8./1024. as tracked_base_table_MB,
change_tracking_min_valid_version(sot2.object_id) as min_valid_version
FROM sys.internal_tables it
JOIN sys.objects sot1 on it.object_id=sot1.object_id
JOIN sys.schemas AS sct1 on
sot1.schema_id=sct1.schema_id
JOIN sys.dm_db_partition_stats ps1 on
it.object_id = ps1. object_id
and ps1.index_id in (0,1)
LEFT JOIN sys.objects sot2 on it.parent_object_id=sot2.object_id
LEFT JOIN sys.schemas AS sct2 on
sot2.schema_id=sct2.schema_id
LEFT JOIN sys.dm_db_partition_stats ps2 on
sot2.object_id = ps2. object_id
and ps2.index_id in (0,1)
WHERE it.internal_type IN (209, 210);
GO