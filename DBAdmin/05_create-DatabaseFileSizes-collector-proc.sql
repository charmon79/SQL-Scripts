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


	DECLARE cur_DB CURSOR LOCAL FAST_FORWARD FOR
		SELECT
			name
		FROM
			sys.databases;

	OPEN cur_DB;
	FETCH NEXT FROM cur_DB INTO @databaseName;

	WHILE @@FETCH_STATUS = 0
	BEGIN
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
				Type
			,	FileName;
		';

		INSERT INTO dbo.DatabaseFileSizes
		EXEC (@sql);

		FETCH NEXT FROM cur_DB INTO @databaseName;
	END

	CLOSE cur_DB;
	DEALLOCATE cur_DB;
END;

GO
