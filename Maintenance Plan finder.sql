USE msdb;
GO

SELECT
    j.name
,	j.description
,   c.name AS category_name
,   j.enabled
,   CASE WHEN sch.schedule_id IS NOT NULL THEN 1 ELSE 0 END AS IsScheduled
,	dbo.agent_datetime(sch.next_run_date, sch.next_run_time) AS next_run_datetime
FROM
    dbo.sysjobs AS j
    JOIN dbo.syscategories AS c ON c.category_id = j.category_id
    OUTER APPLY (
        SELECT TOP 1
            *
        FROM
            dbo.sysjobschedules AS jsch
        WHERE
            jsch.job_id = j.job_id
            AND dbo.agent_datetime(NULLIF(jsch.next_run_date, 0), jsch.next_run_time) >= GETDATE()
        ORDER BY 
            jsch.next_run_date ASC, jsch.next_run_time ASC
    ) AS sch
WHERE
    1=1
    AND j.enabled = 1
    AND c.name = 'Database Maintenance'
    AND j.name NOT IN (
        'DatabaseBackup - SYSTEM_DATABASES - FULL'
    ,   'DatabaseBackup - USER_DATABASES - FULL'
    ,   'DatabaseBackup - USER_DATABASES - DIFF'
    ,   'DatabaseBackup - USER_DATABASES - LOG'
    ,   'CommandLog Cleanup'
    ,   'DatabaseIntegrityCheck - SYSTEM_DATABASES'
    ,   'DatabaseIntegrityCheck - USER_DATABASES'
    ,   'IndexOptimize - USER_DATABASES'
    ,   'StatisticsOptimize - USER_DATABASES'
    ,   'syspolicy_purge_history'
    ,   'sp_delete_backuphistory'
    ,   'sp_purge_jobhistory'
    ,   'Output File Cleanup'
    ,   'DBAdmin Purge Old Data'
    ,   'Collect Database File IO Stats'
    ,   'Collect Database Storage Stats'
    ,   'Collect sp_WhoIsActive'
    ,   'Collect Wait Stats'
    ,   'sp_cycle_errorlog'
    )
ORDER BY
    j.name
;