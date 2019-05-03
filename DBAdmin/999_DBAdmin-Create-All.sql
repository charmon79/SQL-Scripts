USE master;
GO

/*
IF DB_ID('DBAdmin') IS NOT NULL
EXEC ('ALTER DATABASE DBAdmin SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
DROP DATABASE DBAdmin;');
GO
*/

IF DB_ID('DBAdmin') IS NULL
	EXEC('CREATE DATABASE DBAdmin');
GO

-- set file sizes & growth to something sane
use DBAdmin;
GO

ALTER DATABASE DBAdmin MODIFY FILE (NAME = DBAdmin, SIZE = 256 MB, FILEGROWTH = 256 MB);
GO
ALTER DATABASE DBAdmin MODIFY FILE (NAME = DBAdmin_log, SIZE = 64 MB, FILEGROWTH = 64 MB);
GO
ALTER DATABASE DBAdmin SET RECOVERY SIMPLE;
GO
ALTER AUTHORIZATION ON DATABASE::DBAdmin TO sa;
GO

USE DBAdmin;
GO

IF OBJECT_ID('dbo.Databases') IS NULL
CREATE TABLE dbo.Databases (
	DatabaseName sysname not null
,	Created datetime not null
,	StateDesc nvarchar(60) not null
,	LastSeenOnline datetime null
,	IsReadOnly bit null
,	LastUserAccessTime datetime null
);
GO

ALTER TABLE dbo.Databases ADD CONSTRAINT PK_Databases PRIMARY KEY CLUSTERED (DatabaseName);
GO

USE DBAdmin;
GO

IF OBJECT_ID('dbo.DatabaseFileSizes') IS NULL
CREATE TABLE dbo.DatabaseFileSizes (
	CollectedTime datetime not null
,	DatabaseName sysname not null
,	Type tinyint not null
,	TypeDesc nvarchar(60) NOT NULL
,	FileGroupName sysname null
,	FileName sysname not null
,	PhysicalName nvarchar(260) not null
,	SizeMB numeric(10,2) NOT NULL
,	UsedMB numeric(10,2) NULL -- because FILESTREAM / In-Memory don't report used MB
,	FreeMB AS SizeMB - UsedMB PERSISTED
);

ALTER TABLE dbo.DatabaseFileSizes ADD CONSTRAINT PK_DatabaseFileSizes PRIMARY KEY CLUSTERED (CollectedTime, DatabaseName, Type, FileName);
GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_Databases') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_Databases AS RETURN;');
GO

ALTER PROCEDURE dbo.Collect_Databases
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #Databases (
		DatabaseName sysname not null primary key clustered
	,	Created datetime not null
	,	StateDesc nvarchar(60) not null
	,	LastSeenOnline datetime null
	,	IsReadOnly bit null
	,	LastUserAccessTime datetime null
	);

	INSERT #Databases
	SELECT
		d.name AS DatabaseName
	,	d.create_date AS Created
	,	d.state_desc AS StateDesc
	,	CASE WHEN d.state = 0 THEN GETDATE() ELSE NULL END AS LastSeenOnline
	,	d.is_read_only AS IsReadOnly
	,	IndexStats.LastUserAccessTime
	FROM
		sys.databases AS d
		CROSS APPLY (
			SELECT
				MAX(COALESCE(last_user_seek, last_user_scan, last_user_update)) AS LastUserAccessTime
			FROM
				sys.dm_db_index_usage_stats
			WHERE
				database_id = d.database_id
		) AS IndexStats
	;

	-- when matched then update
	UPDATE d
	SET
		Created = du.Created
	,	StateDesc = du.StateDesc
	,	LastSeenOnline = ISNULL(du.LastSeenOnline, d.LastSeenOnline)
	,	IsReadOnly = du.IsReadOnly
	,	LastUserAccessTime = ISNULL(du.LastUserAccessTime, d.LastUserAccessTime)
	FROM
		dbo.Databases AS d
		JOIN #Databases AS du ON du.DatabaseName = d.DatabaseName

	-- when not matched by target then insert
	INSERT dbo.Databases (
		DatabaseName
	,	Created
	,	StateDesc
	,	LastSeenOnline
	,	IsReadOnly
	,	LastUserAccessTime
	)
	SELECT
		du.DatabaseName
	,	du.Created
	,	du.StateDesc
	,	du.LastSeenOnline
	,	du.IsReadOnly
	,	du.LastUserAccessTime
	FROM
		#Databases AS du
		LEFT JOIN dbo.Databases AS d ON d.DatabaseName = du.DatabaseName
	WHERE
		d.DatabaseName IS NULL
	;

	-- when not matched by source then update
	UPDATE d
	SET
		StateDesc = 'DROPPED'
	,	IsReadOnly = NULL
	,	LastUserAccessTime = NULL
	FROM
		dbo.Databases AS d
		LEFT JOIN #Databases AS du ON du.DatabaseName = d.DatabaseName
	WHERE
		du.DatabaseName IS NULL
	;

END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_DatabaseFileSizes') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_DatabaseFileSizes AS RETURN');
GO
ALTER PROCEDURE dbo.Collect_DatabaseFileSizes
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @databaseName sysname;
	DECLARE @state int;


	DECLARE cur_DB CURSOR LOCAL FAST_FORWARD FOR
		SELECT
			name
		,	state
		FROM
			sys.databases
	;

	OPEN cur_DB;
	FETCH NEXT FROM cur_DB INTO @databaseName, @state;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		
		IF @state = 0 -- if database is online, get current file sizes
			SET @sql = N'
				USE '+quotename(@databaseName)+N';
				SELECT
						GETDATE() AS CollectedTime
					,	DB_NAME() AS DatabaseName
					,   df.type
					,   df.type_desc AS TypeDesc
					,	ds.name AS FileGroupName
					,   df.name AS FileName
					,   df.physical_name AS PhysicalName
					,   (df.size * 8.0) / 1024 AS SizeMB
					,   (FILEPROPERTY(df.name, ''SpaceUsed'') * 8.0) / 1024 AS UsedMB
				FROM    sys.database_files AS df
						LEFT JOIN sys.data_spaces AS ds ON ds.data_space_id = df.data_space_id
				ORDER BY
					df.type
				,	df.name;
			';
		ELSE -- roll forward last collected file sizes for offline/inaccessible databases
			SET @sql = N'
		WITH MostRecentAvailable AS (
			SELECT
				CollectedTime
			,	DatabaseName
			,	Type
			,	TypeDesc
			,	FileGroupName
			,	FileName
			,	PhysicalName
			,	SizeMB
			,	UsedMB
			,	ROW_NUMBER() OVER (PARTITION BY DatabaseName ORDER BY CollectedTime DESC) AS Picker
			FROM
				dbo.DatabaseFileSizes
			WHERE
				DatabaseName = '''+@DatabaseName+'''
		)
		SELECT
				GETDATE() AS CollectedTime
			,	DatabaseName
			,	Type
			,	TypeDesc
			,	FileGroupName
			,	FileName
			,	PhysicalName
			,	SizeMB
			,	UsedMB
		FROM MostRecentAvailable
		WHERE Picker = 1
		';

		INSERT INTO dbo.DatabaseFileSizes
		EXEC (@sql);

		FETCH NEXT FROM cur_DB INTO @databaseName, @state;
	END

	CLOSE cur_DB;
	DEALLOCATE cur_DB;
END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.DatabaseTableSizes') IS NULL
CREATE TABLE dbo.DatabaseTableSizes
(
	CollectedTime DATETIME NOT NULL
,	DatabaseName sysname NOT NULL
,	SchemaName sysname NOT NULL
,	TableName sysname NOT NULL
,	Rows BIGINT NOT NULL
,	ReservedMB DECIMAL(10,2) NOT NULL
,	DataMB DECIMAL(10,2) NOT NULL
,	IndexMB DECIMAL(10,2) NOT NULL
,	UsedMB DECIMAL(10,2) NOT NULL
,	UnusedMB DECIMAL(10,2) NOT NULL
,	ObjectType NVARCHAR(60) NOT NULL
);

ALTER TABLE dbo.DatabaseTableSizes ADD CONSTRAINT PK_DatabaseTableSizes PRIMARY KEY CLUSTERED (CollectedTime, DatabaseName, SchemaName, TableName);
GO
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
USE DBAdmin;
GO

IF OBJECT_ID('dbo.WhoIsActiveStats') IS NULL
CREATE TABLE dbo.WhoIsActiveStats
(
 [collection_time]       DATETIME NOT NULL,
 [session_id]            INT NOT NULL, 
 [elapsed_time_s]		 INT NOT NULL,
 [status]                VARCHAR(30) NOT NULL,
 [blocking_session_id]   INT NULL, 
 [blocked_session_count] INT NULL, 
 [wait_info]             NVARCHAR(4000) NULL, 
 [database_name]         NVARCHAR(128) NULL, 
 [host_name]             NVARCHAR(128) NULL, 
 [login_name]            NVARCHAR(128) NOT NULL, 
 [program_name]          NVARCHAR(128) NULL, 
 [sql_text]              NVARCHAR(MAX) NULL, 
 [sql_command]           NVARCHAR(MAX) NULL, 
 [tran_log_writes]       NVARCHAR(4000) NULL, 
 [CPU]                   INT NULL, 
 [tempdb_allocations]    BIGINT NULL, 
 [tempdb_current]        BIGINT NULL, 
 [reads]                 BIGINT NULL, 
 [writes]                BIGINT NULL, 
 [physical_reads]        BIGINT NULL, 
 [query_plan]            XML NULL, 
 [used_memory]           BIGINT NOT NULL, 
 [tran_start_time]       DATETIME NULL, 
 [open_tran_count]       INT NULL, 
 [percent_complete]      REAL NULL, 
 [additional_info]       XML NULL, 
 [start_time]            DATETIME NOT NULL, 
 [login_time]            DATETIME NULL, 
 [request_id]            INT NULL
);

CREATE CLUSTERED INDEX CIX_WhoIsActiveStats ON dbo.WhoIsActiveStats (collection_time, session_id);
GO

CREATE NONCLUSTERED INDEX IX_LongestRunning ON dbo.WhoIsActiveStats (elapsed_time_s DESC);
GO
USE [DBAdmin]
GO

/****** Object:  StoredProcedure [dbo].[Collect_WhoIsActive]    Script Date: 7/30/2018 10:08:40 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.Collect_WhoIsActive') IS NULL
  EXEC('CREATE PROCEDURE dbo.Collect_WhoIsActive AS RETURN;');
GO
ALTER PROCEDURE [dbo].[Collect_WhoIsActive]
AS

BEGIN
	SET NOCOUNT ON;

	/*
		Catch results in a temp table first, because we're adding an elapsed_time_s calculated
		column to the results. (Adam Machanic returns a text representation of the duration when
		@format_output = 1, but not when @format_output = 0. (I want to use @format_output = 0
		so that important metrics are stored in their raw numeric form, not formatted text.)
	*/
	CREATE TABLE #ResultsTemp
	([collection_time]       DATETIME NOT NULL,
	 [session_id]            INT NOT NULL, 
	 [status]                VARCHAR(30) NOT NULL, 
	 [blocking_session_id]   INT NULL, 
	 [blocked_session_count] INT NULL, 
	 [wait_info]             NVARCHAR(4000) NULL, 
	 [database_name]         NVARCHAR(128) NULL, 
	 [host_name]             NVARCHAR(128) NULL, 
	 [login_name]            NVARCHAR(128) NOT NULL, 
	 [program_name]          NVARCHAR(128) NULL, 
	 [sql_text]              NVARCHAR(MAX) NULL, 
	 [sql_command]           NVARCHAR(MAX) NULL, 
	 [tran_log_writes]       NVARCHAR(4000) NULL, 
	 [CPU]                   INT NULL, 
	 [tempdb_allocations]    BIGINT NULL, 
	 [tempdb_current]        BIGINT NULL, 
	 [reads]                 BIGINT NULL, 
	 [writes]                BIGINT NULL, 
	 [physical_reads]        BIGINT NULL, 
	 [query_plan]            XML NULL, 
	 [used_memory]           BIGINT NOT NULL, 
	 [tran_start_time]       DATETIME NULL, 
	 [open_tran_count]       INT NULL, 
	 [percent_complete]      REAL NULL, 
	 [additional_info]       XML NULL, 
	 [start_time]            DATETIME NOT NULL, 
	 [login_time]            DATETIME NULL, 
	 [request_id]            INT NULL
	);

	EXEC sp_WhoIsActive
		@get_transaction_info = 1
	,	@get_outer_command = 1
	,	@get_full_inner_text = 1
	,	@get_plans = 1
	,	@find_block_leaders = 1
	,	@get_additional_info = 2
	,	@format_output = 0
	,	@output_column_list = '[collection_time][session_id][duration][status][blocking_session_id][blocked_session_count][wait_info][database_name][host_name][login_name][program_name][sql_text][sql_command][tran_log_writes][CPU][tempdb_allocations][tempdb_current][reads][writes][physical_reads][query_plan][used_memory][tran_start_time][open_tran_count][percent_complete][additional_info][start_time][login_time][request_id]'
	,	@destination_table = '#ResultsTemp'
	;


    INSERT INTO dbo.WhoIsActiveStats
    (
        collection_time
      , session_id
      , elapsed_time_s
      , status
      , blocking_session_id
      , blocked_session_count
      , wait_info
      , database_name
      , host_name
      , login_name
      , program_name
      , sql_text
      , sql_command
      , tran_log_writes
      , CPU
      , tempdb_allocations
      , tempdb_current
      , reads
      , writes
      , physical_reads
      , query_plan
      , used_memory
      , tran_start_time
      , open_tran_count
      , percent_complete
      , additional_info
      , start_time
      , login_time
      , request_id
    )
    SELECT
        collection_time
      , session_id
      , DATEDIFF(second, start_time, collection_time) AS elapsed_time_s
      , status
      , blocking_session_id
      , blocked_session_count
      , wait_info
      , database_name
      , host_name
      , login_name
      , program_name
      , sql_text
      , sql_command
      , tran_log_writes
      , CPU
      , tempdb_allocations
      , tempdb_current
      , reads
      , writes
      , physical_reads
      , query_plan
      , used_memory
      , tran_start_time
      , open_tran_count
      , percent_complete
      , additional_info
      , start_time
      , login_time
      , request_id
    FROM
        #resultstemp;
END;

GO


USE [DBAdmin]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.WaitStats') IS NULL
CREATE TABLE [dbo].[WaitStats](
	[PeriodStart] DATETIME NOT NULL,
	[PeriodEnd] DATETIME NOT NULL,
	[WaitType] [nvarchar](60) NOT NULL,
	[Wait_S] [decimal](16, 2) NOT NULL,
	[Resource_S] [decimal](16, 2) NOT NULL,
	[Signal_S] [decimal](16, 2) NOT NULL,
	[WaitCount] [bigint] NOT NULL,
	[Percentage] [decimal](5, 2) NOT NULL,
	[AvgWait_S] [decimal](16, 4) NOT NULL,
	[AvgRes_S] [decimal](16, 4) NOT NULL,
	[AvgSig_S] [decimal](16, 4) NOT NULL
) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = object_id('dbo.WaitStats') AND index_id = 1)
CREATE CLUSTERED INDEX CIX_WaitStats ON dbo.WaitStats (PeriodStart, [Percentage])
GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_WaitStats') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_WaitStats AS RETURN')
GO

ALTER PROCEDURE dbo.Collect_WaitStats @TimeInterval CHAR(8)
AS

SET NOCOUNT ON;

/*============================================================================
  File:     ShortPeriodWaitStats.sql (based on)
  
  Summary:  Short snapshot of wait stats
  
  SQL Server Versions: 2005 onwards
------------------------------------------------------------------------------
  Written by Paul S. Randal, SQLskills.com
  
  (c) 2018, SQLskills.com. All rights reserved.
 
  Last update 6/13/2018
  
  For more scripts and sample code, check out http://www.SQLskills.com
  
  You may alter this code for your own *non-commercial* purposes (e.g. in a
  for-sale commercial tool). Use in your own environment is encouraged.
  You may republish altered code as long as you include this copyright and
  give due credit, but you must obtain prior permission before blogging
  this code.
  
  THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF
  ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED
  TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
  PARTICULAR PURPOSE.
============================================================================*/

DECLARE @PeriodStart DATETIME;
DECLARE @PeriodEnd DATETIME;

CREATE TABLE #SQLSkillsStats1 (
	wait_type NVARCHAR(60) NOT NULL
,	waiting_tasks_count BIGINT NOT NULL
,	wait_time_ms BIGINT NOT NULL
,	max_wait_time_ms BIGINT NOT NULL
,	signal_wait_time_ms BIGINT NOT NULL
);

CREATE TABLE #SQLSkillsStats2 (
	wait_type NVARCHAR(60) NOT NULL
,	waiting_tasks_count BIGINT NOT NULL
,	wait_time_ms BIGINT NOT NULL
,	max_wait_time_ms BIGINT NOT NULL
,	signal_wait_time_ms BIGINT NOT NULL
);

/*
	We want this to run continuously so that we don't have any gaps in stats collection.
	The SQL Agent job should be scheduled to run at SQL Server Agent startup.
*/

WHILE 1=1
BEGIN
	TRUNCATE TABLE #SQLSkillsStats1;
	TRUNCATE TABLE #SQLSkillsStats2;

	SET @PeriodStart = GETDATE();

	INSERT INTO #SQLskillsStats1  
	SELECT [wait_type], [waiting_tasks_count], [wait_time_ms],
		   [max_wait_time_ms], [signal_wait_time_ms]
	FROM sys.dm_os_wait_stats;
  
	WAITFOR DELAY @TimeInterval;

	SET @PeriodEnd = GETDATE();
  
	INSERT INTO #SQLskillsStats2
	SELECT [wait_type], [waiting_tasks_count], [wait_time_ms],
		   [max_wait_time_ms], [signal_wait_time_ms]
	FROM sys.dm_os_wait_stats;
  
	WITH [DiffWaits] AS
	(SELECT
	-- Waits that weren't in the first snapshot
			[ts2].[wait_type],
			[ts2].[wait_time_ms],
			[ts2].[signal_wait_time_ms],
			[ts2].[waiting_tasks_count]
		FROM [#SQLskillsStats2] AS [ts2]
		LEFT OUTER JOIN [#SQLskillsStats1] AS [ts1]
			ON [ts2].[wait_type] = [ts1].[wait_type]
		WHERE [ts1].[wait_type] IS NULL
		AND [ts2].[wait_time_ms] > 0
	UNION
	SELECT
	-- Diff of waits in both snapshots
			[ts2].[wait_type],
			[ts2].[wait_time_ms] - [ts1].[wait_time_ms] AS [wait_time_ms],
			[ts2].[signal_wait_time_ms] - [ts1].[signal_wait_time_ms] AS [signal_wait_time_ms],
			[ts2].[waiting_tasks_count] - [ts1].[waiting_tasks_count] AS [waiting_tasks_count]
		FROM [#SQLskillsStats2] AS [ts2]
		LEFT OUTER JOIN [#SQLskillsStats1] AS [ts1]
			ON [ts2].[wait_type] = [ts1].[wait_type]
		WHERE [ts1].[wait_type] IS NOT NULL
		AND [ts2].[waiting_tasks_count] - [ts1].[waiting_tasks_count] > 0
		AND [ts2].[wait_time_ms] - [ts1].[wait_time_ms] > 0),
	[Waits] AS
		(SELECT
			[wait_type],
			[wait_time_ms] / 1000.0 AS [WaitS],
			([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
			[signal_wait_time_ms] / 1000.0 AS [SignalS],
			[waiting_tasks_count] AS [WaitCount],
			100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
			ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
		FROM [DiffWaits]
		WHERE [wait_type] NOT IN (
			-- These wait types are almost 100% never a problem and so they are
			-- filtered out to avoid them skewing the results. Click on the URL
			-- for more information.
			N'BROKER_EVENTHANDLER', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
			N'BROKER_RECEIVE_WAITFOR', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
			N'BROKER_TASK_STOP', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
			N'BROKER_TO_FLUSH', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
			N'BROKER_TRANSMITTER', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
			N'CHECKPOINT_QUEUE', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
			N'CHKPT', -- https://www.sqlskills.com/help/waits/CHKPT
			N'CLR_AUTO_EVENT', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
			N'CLR_MANUAL_EVENT', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
			N'CLR_SEMAPHORE', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
			N'CXCONSUMER', -- https://www.sqlskills.com/help/waits/CXCONSUMER
 
			-- Maybe comment these four out if you have mirroring issues
			N'DBMIRROR_DBM_EVENT', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
			N'DBMIRROR_EVENTS_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
			N'DBMIRROR_WORKER_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
			N'DBMIRRORING_CMD', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
 
			N'DIRTY_PAGE_POLL', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
			N'DISPATCHER_QUEUE_SEMAPHORE', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
			N'EXECSYNC', -- https://www.sqlskills.com/help/waits/EXECSYNC
			N'FSAGENT', -- https://www.sqlskills.com/help/waits/FSAGENT
			N'FT_IFTS_SCHEDULER_IDLE_WAIT', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
			N'FT_IFTSHC_MUTEX', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
 
			-- Maybe comment these six out if you have AG issues
			N'HADR_CLUSAPI_CALL', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
			N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
			N'HADR_LOGCAPTURE_WAIT', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
			N'HADR_NOTIFICATION_DEQUEUE', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
			N'HADR_TIMER_TASK', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
			N'HADR_WORK_QUEUE', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
 
			N'KSOURCE_WAKEUP', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
			N'LAZYWRITER_SLEEP', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
			N'LOGMGR_QUEUE', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
			N'MEMORY_ALLOCATION_EXT', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
			N'ONDEMAND_TASK_QUEUE', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
			N'PARALLEL_REDO_DRAIN_WORKER', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_DRAIN_WORKER
			N'PARALLEL_REDO_LOG_CACHE', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_LOG_CACHE
			N'PARALLEL_REDO_TRAN_LIST', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_TRAN_LIST
			N'PARALLEL_REDO_WORKER_SYNC', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_SYNC
			N'PARALLEL_REDO_WORKER_WAIT_WORK', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_WAIT_WORK
			N'PREEMPTIVE_XE_GETTARGETSTATE', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
			N'PWAIT_ALL_COMPONENTS_INITIALIZED', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
			N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
			N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
			N'QDS_ASYNC_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
			N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
				-- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
			N'QDS_SHUTDOWN_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
			N'REDO_THREAD_PENDING_WORK', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
			N'REQUEST_FOR_DEADLOCK_SEARCH', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
			N'RESOURCE_QUEUE', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
			N'SERVER_IDLE_CHECK', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
			N'SLEEP_BPOOL_FLUSH', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
			N'SLEEP_DBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
			N'SLEEP_DCOMSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
			N'SLEEP_MASTERDBREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
			N'SLEEP_MASTERMDREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
			N'SLEEP_MASTERUPGRADED', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
			N'SLEEP_MSDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
			N'SLEEP_SYSTEMTASK', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
			N'SLEEP_TASK', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
			N'SLEEP_TEMPDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
			N'SNI_HTTP_ACCEPT', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
			N'SP_SERVER_DIAGNOSTICS_SLEEP', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
			N'SQLTRACE_BUFFER_FLUSH', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
			N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
			N'SQLTRACE_WAIT_ENTRIES', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
			N'WAIT_FOR_RESULTS', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
			N'WAITFOR', -- https://www.sqlskills.com/help/waits/WAITFOR
			N'WAITFOR_TASKSHUTDOWN', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
			N'WAIT_XTP_RECOVERY', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
			N'WAIT_XTP_HOST_WAIT', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
			N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
			N'WAIT_XTP_CKPT_CLOSE', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
			N'XE_DISPATCHER_JOIN', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
			N'XE_DISPATCHER_WAIT', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
			N'XE_TIMER_EVENT' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
		)
		)
	INSERT INTO dbo.WaitStats (
		PeriodStart,
		PeriodEnd,
		WaitType,
		Wait_S,
		Resource_S,
		Signal_S,
		WaitCount,
		Percentage,
		AvgWait_S,
		AvgRes_S,
		AvgSig_S
	)
	SELECT
		@PeriodStart AS PeriodStart,
		@PeriodEnd AS PeriodEnd,
		[W1].[wait_type] AS [WaitType],
		CAST ([W1].[WaitS] AS DECIMAL (16, 2)) AS [Wait_S],
		CAST ([W1].[ResourceS] AS DECIMAL (16, 2)) AS [Resource_S],
		CAST ([W1].[SignalS] AS DECIMAL (16, 2)) AS [Signal_S],
		[W1].[WaitCount] AS [WaitCount],
		CAST ([W1].[Percentage] AS DECIMAL (5, 2)) AS [Percentage],
		CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (16, 4)) AS [AvgWait_S],
		CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (16, 4)) AS [AvgRes_S],
		CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (16, 4)) AS [AvgSig_S]
	FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2]
		ON [W2].[RowNum] <= [W1].[RowNum]
	GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS],
		[W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount], [W1].[Percentage]
	HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95; -- percentage threshold

END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.DatabaseFileIOStats') IS NULL
CREATE TABLE dbo.DatabaseFileIOStats
(
	PeriodStart datetime not null
,	PeriodEnd datetime not null
,	DatabaseName sysname not null
,	FileName sysname not null
,	Sample_ms bigint not null
,	Reads bigint not null
,	BytesRead bigint not null
,	ReadStall_ms bigint not null
,	AvgReadLatency_s decimal(10,6) null
,	Writes bigint not null
,	BytesWritten bigint not null
,	WriteStall_ms bigint not null
,	AvgWriteLatency_s decimal(10,6) null
,	TotalStall_ms bigint not null
,	AvgOverallLatency_s decimal(10,6) null
);

ALTER TABLE dbo.DatabaseFileIOStats ADD CONSTRAINT PK_DatabaseFileIOStats PRIMARY KEY CLUSTERED (PeriodStart, DatabaseName, FileName);
GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_DatabaseFileIOStats') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_DatabaseFileIOStats AS RETURN');
GO

ALTER PROCEDURE dbo.Collect_DatabaseFileIOStats @TimeInterval CHAR(8)
AS
BEGIN

	SET NOCOUNT ON;

	CREATE TABLE #sample1
	(
		CollectedTime datetime not null
	,	DatabaseID int not null
	,	FileID int not null
	,	Sample_ms bigint not null
	,	Reads bigint not null
	,	BytesRead bigint not null
	,	ReadStall_ms bigint not null
	,	Writes bigint not null
	,	BytesWritten bigint not null
	,	WriteStall_ms bigint not null
	,	TotalStall_ms bigint not null
	);

	CREATE TABLE #sample2
	(
		CollectedTime datetime not null
	,	DatabaseID int not null
	,	FileID int not null
	,	Sample_ms bigint not null
	,	Reads bigint not null
	,	BytesRead bigint not null
	,	ReadStall_ms bigint not null
	,	Writes bigint not null
	,	BytesWritten bigint not null
	,	WriteStall_ms bigint not null
	,	TotalStall_ms bigint not null
	);


	/*
		We want this to run continuously so that we don't have any gaps in stats collection.
		The SQL Agent job should be scheduled to run at SQL Server Agent startup.
	*/
	WHILE 1=1
	BEGIN
		
		TRUNCATE TABLE #sample1;
		TRUNCATE TABLE #sample2;

		INSERT INTO #sample1
		SELECT
			GETDATE() AS CollectedTime
		,	vfs.database_id AS DatabaseID
		,	vfs.file_id AS FileID
		,	CASE WHEN vfs.sample_ms < 0 THEN CAST(vfs.sample_ms AS BIGINT) + 2147483647 + 2147483647 ELSE CAST(vfs.sample_ms AS bigint) END AS Sample_ms -- because SQL 2008 uses INT and rolls over to min int
		,	vfs.num_of_reads AS Reads
		,	vfs.num_of_bytes_read AS BytesRead
		,	vfs.io_stall_read_ms AS ReadStall_ms
		,	vfs.num_of_writes AS Writes
		,	vfs.num_of_bytes_written AS BytesWritten
		,	vfs.io_stall_write_ms AS WriteStall_ms
		,	vfs.io_stall AS TotalStall_ms
		FROM
			sys.dm_io_virtual_file_stats(null, null) AS vfs
		;

		WAITFOR DELAY @TimeInterval;

		INSERT INTO #sample2
		SELECT
			GETDATE() AS CollectedTime
		,	vfs.database_id AS DatabaseID
		,	vfs.file_id AS FileID
		,	CASE WHEN vfs.sample_ms < 0 THEN CAST(vfs.sample_ms AS BIGINT) + 2147483647 + 2147483647 ELSE CAST(vfs.sample_ms AS bigint) END AS Sample_ms
		,	vfs.num_of_reads AS Reads
		,	vfs.num_of_bytes_read AS BytesRead
		,	vfs.io_stall_read_ms AS ReadStall_ms
		,	vfs.num_of_writes AS Writes
		,	vfs.num_of_bytes_written AS BytesWritten
		,	vfs.io_stall_write_ms AS WriteStall_ms
		,	vfs.io_stall AS TotalStall_ms
		FROM
			sys.dm_io_virtual_file_stats(null, null) AS vfs
		;

		WITH DeltaCalculator AS (
			SELECT
				s1.CollectedTime AS PeriodStart
			,	s2.CollectedTime AS PeriodEnd
			,	d.name AS DatabaseName
			,	mf.name AS FileName
			,	s2.Sample_ms - s1.Sample_ms AS Sample_ms
			,	s2.Reads - s1.Reads AS Reads
			,	s2.BytesRead - s1.BytesRead AS BytesRead
			,	s2.ReadStall_ms - s1.ReadStall_ms AS ReadStall_ms
			,	s2.Writes - s1.Writes AS Writes
			,	s2.BytesWritten - s1.BytesWritten AS BytesWritten
			,	s2.WriteStall_ms - s1.WriteStall_ms AS WriteStall_ms
			,	s2.TotalStall_ms - s1.TotalStall_ms AS TotalStall_ms
			FROM
				#sample1 AS s1
				JOIN #sample2 AS s2 ON s2.DatabaseID = s1.DatabaseID AND s2.FileID = s1.FileID
				JOIN sys.databases AS d ON d.database_id = s2.DatabaseID
				JOIN sys.master_files AS mf ON mf.database_id = s2.DatabaseID AND mf.file_id = s2.FileID
		)
		INSERT INTO dbo.DatabaseFileIOStats
		SELECT
			PeriodStart
		,	PeriodEnd
		,	DatabaseName
		,	FileName
		,	Sample_ms
		,	Reads
		,	BytesRead
		,	ReadStall_ms
		,	CAST((1.0 * ReadStall_ms / NULLIF(Reads, 0)) / 1000.0 AS DECIMAL(10,6)) AS AvgReadLatency_s
		,	Writes
		,	BytesWritten
		,	WriteStall_ms
		,	CAST((1.0 * WriteStall_ms / NULLIF(Writes, 0)) / 1000.0 AS DECIMAL(10,6)) AS AvgWriteLatency_s
		,	TotalStall_ms
		,	CAST((1.0 * TotalStall_ms / NULLIF(Reads + Writes, 0)) / 1000.0 AS DECIMAL(10,6)) AS AvgOverallLatency_s
		FROM
			DeltaCalculator
		;

	END;

END;
GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_WhoIsActive') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_WhoIsActive AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_WhoIsActive
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.WhoIsActiveStats
	WHERE collection_time < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_DatabaseFileIOStats') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_DatabaseFileIOStats AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_DatabaseFileIOStats
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.DatabaseFileIOStats
	WHERE PeriodEnd < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_DatabaseFileSizes') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_DatabaseFileSizes AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_DatabaseFileSizes
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.DatabaseFileSizes
	WHERE CollectedTime < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_DatabaseTableSizes') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_DatabaseTableSizes AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_DatabaseTableSizes
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.DatabaseTableSizes
	WHERE CollectedTime < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_WaitStats') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_WaitStats AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_WaitStats
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.WaitStats
	WHERE PeriodEnd < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
