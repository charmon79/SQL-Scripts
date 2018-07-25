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
