--------------------------------------------------------------------------------- 
--Database Backups for all databases For Previous Week 
--------------------------------------------------------------------------------- 
WITH backups AS (
SELECT
    CONVERT(CHAR(100), SERVERPROPERTY('Servername')) AS Server
  , bs.database_name
  , bs.backup_start_date
  , bs.backup_finish_date
  , bs.expiration_date
  , CASE bs.type
        WHEN 'D' THEN 'Full'
        WHEN 'L' THEN 'Log'
        WHEN 'I' THEN 'Diff'
       END AS backup_type
  , bs.backup_size / 1048576.0 AS backup_size_mb
  , bs.compressed_backup_size / 1048576.0 AS compressed_backup_size_mb
  , CAST(100 * (1 - ((1.0 * bs.compressed_backup_size) / bs.backup_size)) AS DECIMAL(5,2)) AS compression_ratio
  , bmf.logical_device_name
  , bmf.physical_device_name
  , bs.name AS backupset_name
  , bs.description
FROM
    msdb.dbo.backupmediafamily AS bmf
    INNER JOIN msdb.dbo.backupset AS bs
        ON bmf.media_set_id = bs.media_set_id
WHERE bs.backup_start_date >= DATEADD(day, -5, GETDATE())
)
SELECT
    database_name
,   backup_type
,   count(1) AS count
,   sum(compressed_backup_size_mb) AS total_compressed_backup_mb
FROM
    backups
GROUP BY
    database_name
,   backup_type
;