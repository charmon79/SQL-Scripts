/************************************************************************************************************
	!!! work in progress, not giving desired output yet
************************************************************************************************************/

DECLARE @DatabaseName sysname = 'CADNCEPRD';

-- find the most recent full backup
WITH LatestFull AS (
	SELECT
		drs.database_guid
	,	bs.database_name
	,	bs.backup_finish_date
	,	bs.first_lsn
	,	ROW_NUMBER() OVER (PARTITION BY drs.database_guid ORDER BY bs.backup_finish_date DESC) AS Latest
	FROM
		sys.databases AS d
		JOIN sys.database_recovery_status AS drs ON drs.database_id = d.database_id
		JOIN msdb.dbo.backupset AS bs ON bs.database_guid = drs.database_guid
	WHERE
		d.name = @DatabaseName
		AND bs.type = 'D'
		--AND bs.is_snapshot = 0
)
,	Logs AS (
	SELECT

	FROM
		sys.databases AS d
		JOIN sys.database_recovery_status AS drs ON drs.database_id = d.database_id
		JOIN msdb.dbo.backupset AS bs ON bs.database_guid = drs.database_guid
	WHERE
		d.name = @DatabaseName
)
select *
from LatestDiff
WHERE Latest = 1