WITH LastBackups AS (
select
	d.name
,	d.recovery_model_desc
,	MAX(fb.backup_finish_date) AS last_full_backup
,	MAX(lb.backup_finish_date) AS last_log_backup
FROM
	sys.databases AS d
	JOIN sys.database_recovery_status AS drs ON drs.database_id = d.database_id
	LEFT JOIN msdb.dbo.backupset AS fb ON fb.database_guid = drs.database_guid and fb.type = 'D'
	LEFT JOIN msdb.dbo.backupset AS lb ON lb.database_guid = drs.database_guid and lb.type = 'L'
GROUP BY
	d.name
,	d.recovery_model_desc
)
-- FULL & BULK_LOGGED recovery missing log backups (except for model)
SELECT
	name
,	'FULL recovery with no log backup' AS problem
FROM LastBackups
WHERE recovery_model_desc IN ('FULL', 'BULK_LOGGED') AND last_log_backup IS NULL AND name <> 'model'
UNION ALL
-- Anything missing a FULL backup (except for tempdb)
SELECT
	name
,	'No full database backup' AS problem
FROM LastBackups
WHERE last_full_backup IS NULL AND name <> 'tempdb'
ORDER BY name, problem
;