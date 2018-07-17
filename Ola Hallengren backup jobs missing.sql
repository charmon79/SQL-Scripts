/*
	Return a row if instance does NOT have active Ola Hallengren backups.
*/

WITH finder AS (
SELECT
	COUNT(1) as jobcount
FROM
	msdb.dbo.sysjobs AS j
	JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = j.job_id
	JOIN msdb.dbo.sysjobschedules AS jsch ON jsch.job_id = j.job_id
	JOIN msdb.dbo.sysschedules AS sch ON sch.schedule_id = jsch.schedule_id
WHERE
	j.name LIKE 'DatabaseBackup%'
	AND j.enabled = 1
	AND sch.enabled = 1
)
SELECT *
FROM finder
where jobcount < 2 -- should have at least 'SYSTEM_DATABASES - FULL' and 'USER_DATABASES - FULL'