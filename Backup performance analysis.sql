--------------------------------------------------------------------------------- 
--Database Backups for all databases For Previous Week 
--------------------------------------------------------------------------------- 
DECLARE @numdays int;
SET @numdays = 30;

WITH backups AS (
SELECT
    bs.database_name
  , bs.backup_start_date
  , bs.backup_finish_date
  , bs.expiration_date
  , bs.type
  --, CASE bs.type
  --      WHEN 'D' THEN 'Full'
  --      WHEN 'L' THEN 'Log'
  --      WHEN 'I' THEN 'Diff'
  --     END AS backup_type
  --, bs.backup_size / 1048576.0 AS backup_size_mb
  --, bs.compressed_backup_size / 1048576.0 AS compressed_backup_size_mb
  --, CAST(100 * (1 - ((1.0 * bs.compressed_backup_size) / bs.backup_size)) AS DECIMAL(5,2)) AS compression_ratio
  , bs.backup_size
  , bs.compressed_backup_size
  , bmf.device_type
  , bmf.logical_device_name
  , bmf.physical_device_name
  , bs.name AS backupset_name
  , bs.description
FROM
    msdb.dbo.backupmediafamily AS bmf
    INNER JOIN msdb.dbo.backupset AS bs
        ON bmf.media_set_id = bs.media_set_id
WHERE bs.backup_start_date >= DATEADD(day, -@numdays, GETDATE())
)
/* -- summary
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
--*/
SELECT
    database_name
,   backup_start_date
,   backup_finish_date
,   CASE type
        WHEN 'D' THEN 'Full'
        WHEN 'L' THEN 'Log'
        WHEN 'I' THEN 'Diff'
       END AS backup_type
,   backup_size / 1048576.0 AS backup_size_mb
,   compressed_backup_size / 1048576.0 AS compressed_backup_size_mb
,   CAST(100 * (1 - ((1.0 * compressed_backup_size) / backup_size)) AS DECIMAL(5,2)) AS compression_ratio
,   DATEDIFF(second, backup_start_date, backup_finish_date) AS duration_seconds
,   CAST(( (compressed_backup_size) / ISNULL(NULLIF(datediff(second, backup_start_date, backup_finish_date), 0), 1) ) / 1048576.0 AS DECIMAL(8,2)) AS real_throughput_MBps
,   CAST(( (backup_size) / ISNULL(NULLIF(datediff(second, backup_start_date, backup_finish_date), 0), 1) ) / 1048576.0 AS DECIMAL(8,2)) AS effective_throughput_MBps
,   CASE device_type
        WHEN 2 THEN 'Disk'
        WHEN 5 THEN 'Tape'
        WHEN 7 THEN 'Virtual device'
        WHEN 9 THEN 'Azure Storage'
        WHEN 105 THEN 'A permanent backup device'
    END AS device_type
,   physical_device_name
FROM
    backups
WHERE
    device_type not in (7) -- ignore VSS backups
    AND database_name = 'CADNCEPRD'
    AND type = 'D'
ORDER BY
    backup_start_date desc
;