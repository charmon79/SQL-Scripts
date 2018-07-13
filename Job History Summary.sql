DECLARE @period TINYINT = 3
/*
	@period parameter options:
		1 = past day
		2 = past week
		3 = past month
		4 = past year
		5 = all

	(Naturally, job history retention affects what you'll get,
	and it's very unlikely you'll have full history going back
	further than a day for jobs that run very frequently e.g.
	every few minutes.)
*/

/* script body begins */
DECLARE
    @periodStart DATETIME = NULL
,   @periodEnd DATETIME = NULL

SET @periodEnd = GETDATE();

SET @periodStart =
	CASE @period
		WHEN 1 THEN DATEADD(day, -1, getdate())
		WHEN 2 THEN DATEADD(week, -1, getdate())
		WHEN 3 THEN DATEADD(month, -1, getdate())
		WHEN 4 THEN DATEADD(year, -1, getdate())
		WHEN 5 THEN CAST('1900-01-01' AS DATETIME)
	END

IF @periodStart IS NULL
    --SET @periodStart = DATEADD(DAY, -7, @periodEnd);
	SET @periodStart = CAST('1900-01-01' AS DATETIME);

WITH cteJobHistory AS (
    SELECT
        jh.job_id
    ,   jh.step_id
    ,   jh.run_status
    ,   jh.run_date
    ,   jh.run_time
    ,   ((jh.run_duration / 10000 * 3600 + (jh.run_duration / 100) % 100 * 60 + jh.run_duration % 100 ) ) AS duration_seconds
    ,   CAST(
				  CAST(jh.run_duration / 10000 AS VARCHAR(30)) -- hours
              +   ':'
              +   CAST((jh.run_duration / 100) % 100 AS VARCHAR(30)) -- minutes
              +   ':'
              +   CAST((jh.run_duration % 100) AS VARCHAR(30)) -- seconds
            AS TIME(3)) AS duration_time
    ,   ROW_NUMBER() OVER (PARTITION BY jh.job_id ORDER BY jh.run_date DESC, jh.run_time DESC) AS LastRun
    FROM
        msdb.dbo.sysjobs AS j
        LEFT JOIN msdb.dbo.sysjobhistory AS jh ON jh.job_id = j.job_id
	WHERE
		jh.step_id = 0
		AND msdb.dbo.agent_datetime(jh.run_date, jh.run_time) BETWEEN @periodStart AND @periodEnd
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
,   ISNULL(jsch.scheduled, 'No') AS [Is Scheduled]
,	CASE WHEN j.notify_level_email > 1 AND j.notify_email_operator_id > 0 THEN 'Yes' ELSE 'No' END AS [Email Notify on Fail]
,	CASE WHEN j.notify_level_eventlog > 1  THEN 'Yes' ELSE 'No' END AS [Event Log on Fail]
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
FROM
    msdb.dbo.sysjobs AS j
    LEFT JOIN cteJobHistory AS jh
        ON jh.job_id = j.job_id
    LEFT JOIN cteJobLastRun AS jlr
        ON jlr.job_id = j.job_id
    LEFT JOIN cteJobSchedules AS jsch
        ON jsch.job_id = j.job_id

GROUP BY 
    CASE j.enabled
        WHEN 1 THEN 'Enabled'
        ELSE 'Disabled'
    END
,	CASE WHEN j.notify_level_email > 1 AND j.notify_email_operator_id > 0 THEN 'Yes' ELSE 'No' END
,	CASE WHEN j.notify_level_eventlog > 1  THEN 'Yes' ELSE 'No' END
,   msdb.dbo.agent_datetime(jlr.run_date, jlr.run_time)
,   j.name
,   jlr.last_run_status
,   jsch.scheduled
ORDER BY [Job Name]
;
