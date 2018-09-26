/*
	Work in progress. Goal is to pull back the whole log chain and identify any breaks.
*/


DECLARE @DatabaseName sysname = 'LME';



WITH backups AS (
SELECT /* Columns for retrieving information */
       -- CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS SRVNAME, 
       bs.database_name,
       bs.backup_start_date,
       bs.backup_finish_date,
       -- bs.expiration_date, 

       CASE bs.type
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Diff'
            WHEN 'L' THEN 'Log'
       END  AS backup_type,
       -- bs.backup_size / 1024 / 1024 as [backup_size MB],  
       bmf.logical_device_name,
       bmf.physical_device_name,
	   RIGHT(
				bmf.physical_device_name, 
				CASE WHEN CHARINDEX('/', REVERSE(bmf.physical_device_name)) > 0 THEN CHARINDEX('/', REVERSE(bmf.physical_device_name)) - 1 ELSE LEN(bmf.physical_device_name) END
			) AS file_name,
       -- bs.name AS backupset_name,
       -- bs.description,
       bs.is_copy_only,
       bs.is_snapshot,
       bs.checkpoint_lsn,
       bs.database_backup_lsn,
       bs.differential_base_lsn,
       bs.first_lsn,
       bs.fork_point_lsn,
       bs.last_lsn
	,  ROW_NUMBER() OVER(order by backup_start_date) AS sequence
FROM   msdb.dbo.backupmediafamily AS bmf
       INNER JOIN msdb.dbo.backupset AS bs
            ON  bmf.media_set_id = bs.media_set_id 
WHERE  1 = 1
	AND bs.backup_start_date >= DATEADD(day, -1, CAST(getdate() as date))  -- 7 days old or younger
    AND database_name IN (@DatabaseName) -- database names
       -- AND     database_name IN ('rtc')  -- database names

        /* -------------------------------------------------------------------------------
        ORDER Clause for other statements
        ---------------------------------------------------------------------------------- */
        --ORDER BY        bs.database_name, bs.backup_finish_date -- order clause

        ---WHERE msdb..backupset.type = 'I' OR  msdb..backupset.type = 'D'
)
/*
,	FirstLogBackup AS (
	SELECT *
	FROM backups AS l
		CROSS APPLY (
			SELECT TOP 1 first_lsn
			FROM backups
			WHERE
				first_lsn = l.first_lsn
				AND backup_type = 'Full'

		)
	WHERE backup_type = 'Log'
)
--*/
/*
SELECT
	b1.*
,	b2.last_lsn AS previous_log_lsn
FROM backups AS b1
	LEFT JOIN backups AS b2 ON b1.first_lsn = b2.last_lsn
ORDER BY
       --2,

       2       DESC,
       3       DESC 
--*/
select *
from backups
