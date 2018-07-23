/*
	Work in progress. Goal is to pull back the whole log chain and identify any breaks.
*/


DECLARE @DatabaseName sysname = 'WideWorldImporters';

WITH backups AS (
SELECT /* Columns for retrieving information */
       -- CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS SRVNAME, 
       msdb.dbo.backupset.database_name,
       msdb.dbo.backupset.backup_start_date,
       msdb.dbo.backupset.backup_finish_date,
       -- msdb.dbo.backupset.expiration_date, 

       CASE msdb.dbo.backupset.type
            WHEN 'D' THEN 'Full'
            WHEN 'I' THEN 'Diff'
            WHEN 'L' THEN 'Log'
       END  AS backup_type,
       -- msdb.dbo.backupset.backup_size / 1024 / 1024 as [backup_size MB],  
       msdb.dbo.backupmediafamily.logical_device_name,
       msdb.dbo.backupmediafamily.physical_device_name,
       -- msdb.dbo.backupset.name AS backupset_name,
       -- msdb.dbo.backupset.description,
       msdb.dbo.backupset.is_copy_only,
       msdb.dbo.backupset.is_snapshot,
       msdb.dbo.backupset.checkpoint_lsn,
       msdb.dbo.backupset.database_backup_lsn,
       msdb.dbo.backupset.differential_base_lsn,
       msdb.dbo.backupset.first_lsn,
       msdb.dbo.backupset.fork_point_lsn,
       msdb.dbo.backupset.last_lsn
	,  ROW_NUMBER() OVER(order by backup_start_date) AS sequence
FROM   msdb.dbo.backupmediafamily
       INNER JOIN msdb.dbo.backupset
            ON  msdb.dbo.backupmediafamily.media_set_id = msdb.dbo.backupset.media_set_id 

        /* ----------------------------------------------------------------------------
        Generic WHERE statement to simplify selection of more WHEREs    
        -------------------------------------------------------------------------------*/
WHERE  1 = 1

       /* ----------------------------------------------------------------------------
       WHERE statement to find Device Backups with '{' and date n days back
       ------------------------------------------------------------------------------- */
       -- AND     physical_device_name LIKE '{%'

       /* -------------------------------------------------------------------------------
       WHERE statement to find Backups saved in standard directories, msdb.dbo.backupfile AS b 
       ---------------------------------------------------------------------------------- */
       -- AND     physical_device_name  LIKE '[fF]:%'                          -- STANDARD F: Backup Directory
       -- AND     physical_device_name  NOT LIKE '[nN]:%'                      -- STANDARD N: Backup Directory

       -- AND     physical_device_name  NOT LIKE '{%'                          -- Outstanding Analysis
       -- AND     physical_device_name  NOT LIKE '%$\Sharepoint$\%' ESCAPE '$' -- Sharepoint Backs up to Share
       -- AND     backupset_name NOT LIKE '%Galaxy%'                           -- CommVault Sympana Backup


       /* -------------------------------------------------------------------------------
       WHERE Statement to find backup information for a certain period of time, msdb.dbo.backupset AS b 
       ---------------------------------------------------------------------------------- 
       
       AND    (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) <= GETDATE())  -- n days old or older

       */

	   AND    (CONVERT(datetime, msdb.dbo.backupset.backup_start_date, 102) >= GETDATE() - 7)  -- 7 days old or younger

       /* -------------------------------------------------------------------------------
       WHERE Statement to find backup information for (a) given database(s) 
       ---------------------------------------------------------------------------------- */
       AND database_name IN (@DatabaseName) -- database names
       -- AND     database_name IN ('rtc')  -- database names

        /* -------------------------------------------------------------------------------
        ORDER Clause for other statements
        ---------------------------------------------------------------------------------- */
        --ORDER BY        msdb.dbo.backupset.database_name, msdb.dbo.backupset.backup_finish_date -- order clause

        ---WHERE msdb..backupset.type = 'I' OR  msdb..backupset.type = 'D'
)
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
SELECT
	b1.*
,	b2.last_lsn AS previous_log_lsn
FROM backups AS b1
	LEFT JOIN backups AS b2 ON b1.first_lsn = b2.last_lsn
ORDER BY
       --2,

       2       DESC,
       3       DESC 