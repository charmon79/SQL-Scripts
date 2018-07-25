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
