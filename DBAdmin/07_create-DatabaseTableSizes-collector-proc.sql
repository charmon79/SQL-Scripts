USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_DatabaseTableSizes') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_DatabaseTableSizes AS RETURN');
GO
ALTER PROCEDURE dbo.Collect_DatabaseTableSizes
AS
BEGIN;

	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @databaseName sysname;


	DECLARE cur_DB CURSOR LOCAL FAST_FORWARD FOR
		SELECT
			name
		FROM
			sys.databases
		WHERE
			state = 0 -- ONLINE (all other database statuses will fail this query)
	;

	OPEN cur_DB;
	FETCH NEXT FROM cur_DB INTO @databaseName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @sql = N'
			USE '+quotename(@databaseName)+N';
			WITH extra AS
				(   -- Get info for FullText indexes, XML Indexes, etc
					SELECT  sit.[object_id],
							sit.[parent_id],
							ps.[index_id],
							SUM(ps.reserved_page_count) AS [reserved_page_count],
							SUM(ps.used_page_count) AS [used_page_count]
					FROM    sys.dm_db_partition_stats ps
					INNER JOIN  sys.internal_tables sit
							ON  sit.[object_id] = ps.[object_id]
					WHERE   sit.internal_type IN
							   (202, 204, 207, 211, 212, 213, 214, 215, 216, 221, 222, 236)
					GROUP BY    sit.[object_id],
								sit.[parent_id],
								ps.[index_id]
				), agg AS
				(   -- Get info for Tables, Indexed Views, etc (including "extra")
					SELECT  ps.[object_id] AS [ObjectID],
							ps.index_id AS [IndexID],
							SUM(ps.in_row_data_page_count) AS [InRowDataPageCount],
							SUM(ps.used_page_count) AS [UsedPageCount],
							SUM(ps.reserved_page_count) AS [ReservedPageCount],
							SUM(ps.row_count) AS [RowCount],
							SUM(ps.lob_used_page_count + ps.row_overflow_used_page_count)
									AS [LobAndRowOverflowUsedPageCount]
					FROM    sys.dm_db_partition_stats ps
					GROUP BY    ps.[object_id],
								ps.[index_id]
					UNION ALL
					SELECT  ex.[parent_id] AS [ObjectID],
							ex.[object_id] AS [IndexID],
							0 AS [InRowDataPageCount],
							SUM(ex.used_page_count) AS [UsedPageCount],
							SUM(ex.reserved_page_count) AS [ReservedPageCount],
							0 AS [RowCount],
							0 AS [LobAndRowOverflowUsedPageCount]
					FROM    extra ex
					GROUP BY    ex.[parent_id],
								ex.[object_id]
				), spaceused AS
				(
				SELECT  agg.[ObjectID],
						OBJECT_SCHEMA_NAME(agg.[ObjectID]) AS [SchemaName],
						OBJECT_NAME(agg.[ObjectID]) AS [TableName],
						SUM(CASE
								WHEN (agg.IndexID < 2) THEN agg.[RowCount]
								ELSE 0
							END) AS [Rows],
						SUM(agg.ReservedPageCount) * 8 AS [ReservedKB],
						SUM(agg.LobAndRowOverflowUsedPageCount +
							CASE
								WHEN (agg.IndexID < 2) THEN (agg.InRowDataPageCount)
								ELSE 0
							END) * 8 AS [DataKB],
						SUM(agg.UsedPageCount - agg.LobAndRowOverflowUsedPageCount -
							CASE
								WHEN (agg.IndexID < 2) THEN agg.InRowDataPageCount
								ELSE 0
							END) * 8 AS [IndexKB],
						SUM(agg.ReservedPageCount - agg.UsedPageCount) * 8 AS [UnusedKB],
						SUM(agg.UsedPageCount) * 8 AS [UsedKB]
				FROM    agg
				GROUP BY    agg.[ObjectID],
							OBJECT_SCHEMA_NAME(agg.[ObjectID]),
							OBJECT_NAME(agg.[ObjectID])
				)
				SELECT GETDATE() AS CollectedTime,
					   DB_NAME() AS DatabaseName,
					   sp.SchemaName,
					   sp.TableName,
					   sp.[Rows],
					   (sp.ReservedKB / 1024.0) AS [ReservedMB],
					   (sp.DataKB / 1024.0) AS [DataMB],
					   (sp.IndexKB / 1024.0) AS [IndexMB],
					   (sp.UsedKB / 1024.0) AS [UsedMB],
					   (sp.UnusedKB / 1024.0) AS [UnusedMB],
					   so.[type_desc] AS [ObjectType]
				FROM   spaceused sp
				INNER JOIN sys.objects so
						ON so.[object_id] = sp.ObjectID
				WHERE
					sp.SchemaName <> ''sys'' -- all user tables
					OR (sp.SchemaName = ''sys'' AND sp.ReservedKB > 0) -- non-empty system tables
				;
		';

		INSERT INTO dbo.DatabaseTableSizes
		EXEC (@sql);

		FETCH NEXT FROM cur_DB INTO @databaseName;
	END

	CLOSE cur_DB;
	DEALLOCATE cur_DB;

END;
GO
