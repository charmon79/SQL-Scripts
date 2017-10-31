
--/*
DECLARE
    @periodStart DATETIME = NULL
,   @periodEnd DATETIME = NULL
--*/

IF @periodEnd IS NULL
    SET @periodEnd = GETDATE();

IF @periodStart IS NULL
    SET @periodStart = DATEADD(DAY, -1, @periodEnd);

WITH cteJobHistory AS (
    SELECT
        jh.job_id
    ,   jh.step_id
    ,   jh.run_status
    ,   jh.run_date
    ,   jh.run_time
    ,   ((jh.run_duration / 10000 * 3600 + (jh.run_duration / 100) % 100 * 60 + jh.run_duration % 100 ) ) AS duration_seconds
    ,   CAST(CONCAT(
                  jh.run_duration / 10000 -- hours
              ,   ':'
              ,   (jh.run_duration / 100) % 100 -- minutes
              ,   ':'
              ,   (jh.run_duration % 100) -- seconds
              ) AS TIME(3)) AS duration_time
    ,   ROW_NUMBER() OVER (PARTITION BY jh.job_id ORDER BY jh.run_date DESC, jh.run_time DESC) AS LastRun
    FROM
        msdb.dbo.sysjobs AS j
        LEFT JOIN msdb.dbo.sysjobhistory AS jh ON jh.job_id = j.job_id
)
,   cteJobLastRun AS (
    SELECT
        *
    ,   CASE run_status 
            WHEN 0 THEN 'Failed'
            WHEN 1 THEN 'Success'
            WHEN 2 THEN 'Retry'
            WHEN 3 THEN 'Cancelled'
        END AS last_run_status
    FROM
        cteJobHistory
    WHERE
        cteJobHistory.LastRun = 1
)
,   cteJobSchedules AS (
    SELECT
        jsch.job_id
    ,   sch.freq_type
    ,   sch.freq_interval
    ,   sch.freq_subday_type
    ,   sch.freq_subday_interval
    ,   sch.freq_relative_interval
    ,   sch.freq_recurrence_factor
    ,   sch.active_start_date
    ,   sch.active_end_date
    ,   sch.active_start_time
    ,   sch.active_end_time
    ,   CASE
            WHEN jsch.schedule_id IS NOT NULL AND sch.enabled = 1
                THEN 'Yes'
            ELSE 'No'
        END AS scheduled
    /* TODO: get schedule descriptions working
    ,   CASE sch.freq_type
            WHEN 1 THEN 'One Time'
            WHEN 4 THEN 'Daily'
            WHEN 8 THEN 'Weekly'
            WHEN 16 THEN 'Monthly'
            WHEN 32 THEN '-- FIX THIS --' -- Monthly relative to freq_interval
            WHEN 64 THEN 'On Startup'
            WHEN 128 THEN 'When Idle'
        END AS ScheduleDescription
    --*/
    FROM
        msdb.dbo.sysjobschedules AS jsch
        JOIN msdb.dbo.sysschedules AS sch
            ON sch.schedule_id = jsch.schedule_id
)
SELECT
    j.name AS [Job Name]
,   CASE j.enabled WHEN 1 THEN 'Enabled' ELSE 'Disabled' END AS [Job Status]
,   @periodStart AS [Period Start]
,   @periodEnd AS [Period End]
,   CAST(DATEADD(ss, AVG(jh.duration_seconds),0) AS TIME(3)) AS [Average Run Time]
,   MIN(jh.duration_time) AS [Shortest Run Time]
,   MAX(jh.duration_time) AS [Longest Run Time]
,   SUM(CASE WHEN jh.run_status = 0 THEN 1 ELSE 0 END) AS [Failed Runs]
,   SUM(CASE WHEN jh.run_status = 1 THEN 1 ELSE 0 END) AS [Successful Runs]
,   SUM(CASE WHEN jh.run_status = 2 THEN 1 ELSE 0 END) AS [Retried Runs]
,   SUM(CASE WHEN jh.run_status = 3 THEN 1 ELSE 0 END) AS [Cancelled Runs]
,   msdb.dbo.agent_datetime(jlr.run_date, jlr.run_time) AS [Last Run]
,   jlr.last_run_status AS [Last Run Outcome]
,   ISNULL(jsch.scheduled, 'No') AS [Is Scheduled]
FROM
    msdb.dbo.sysjobs AS j
    JOIN cteJobHistory AS jh
        ON jh.job_id = j.job_id
    JOIN cteJobLastRun AS jlr
        ON jlr.job_id = j.job_id
    LEFT JOIN cteJobSchedules AS jsch
        ON jsch.job_id = j.job_id
WHERE
    jh.step_id = 0
    AND msdb.dbo.agent_datetime(jh.run_date, jh.run_time) BETWEEN @periodStart AND @periodEnd
GROUP BY 
    CASE j.enabled
        WHEN 1 THEN 'Enabled'
        ELSE 'Disabled'
    END
,   msdb.dbo.agent_datetime(jlr.run_date, jlr.run_time)
,   j.name
,   jlr.last_run_status
,   jsch.scheduled
ORDER BY [Job Name]
;

