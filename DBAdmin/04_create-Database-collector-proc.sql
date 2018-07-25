USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_Databases') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_Databases AS RETURN;');
GO

ALTER PROCEDURE dbo.Collect_Databases
AS
BEGIN

	SET NOCOUNT ON;

	WITH DatabaseSummary AS (
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
		)
	MERGE INTO dbo.Databases AS tgt
	USING DatabaseSummary AS src
		ON src.DatabaseName = tgt.DatabaseName
	WHEN MATCHED THEN UPDATE
		SET
			Created = src.Created
		,	StateDesc = src.StateDesc
		,	LastSeenOnline = ISNULL(src.LastSeenOnline, tgt.LastSeenOnline)
		,	IsReadOnly = src.IsReadOnly
		,	LastUserAccessTime = src.LastUserAccessTime
	WHEN NOT MATCHED BY TARGET THEN INSERT (
			DatabaseName
		,	Created
		,	StateDesc
		,	LastSeenOnline
		,	IsReadOnly
		,	LastUserAccessTime
		) VALUES (
			src.DatabaseName
		,	src.Created
		,	src.StateDesc
		,	src.LastSeenOnline
		,	src.IsReadOnly
		,	src.LastUserAccessTime
		)
	WHEN NOT MATCHED BY SOURCE THEN UPDATE
		SET
			StateDesc = 'DROPPED'
		,	IsReadOnly = NULL
		,	LastUserAccessTime = NULL
	;

END;

GO
