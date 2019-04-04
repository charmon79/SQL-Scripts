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
