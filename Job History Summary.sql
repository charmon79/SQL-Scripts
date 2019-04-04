DECLARE @days smallint;
SET @days = 3;

/* script body begins */
DECLARE
    @periodStart DATETIME
,   @periodEnd DATETIME

SET @periodEnd = GETDATE();

SET @periodStart = DATEADD(DAY, -@days, @periodEnd);

WITH cteJobHistory AS (
    SELECT
        jh.job_id
    ,   jh.step_id
    ,   jh.run_status
    ,   jh.run_date
    ,   jh.run_time
    ,   ((jh.run_duration / 10000 * 3600 + (jh.run_duration / 100) % 100 * 60 + jh.run_duration % 100 ) ) AS duration_seconds
    --,   CAST(
				--  CAST(jh.run_duration / 10000 AS VARCHAR(30)) -- hours
    --          +   ':'
    --          +   CAST((jh.run_duration / 100) % 100 AS VARCHAR(30)) -- minutes
    --          +   ':'
    --          +   CAST((jh.run_duration % 100) AS VARCHAR(30)) -- seconds
    --        --AS TIME(3)) AS duration_time
    --        AS datetime) AS duration_time
	,	jh.run_duration
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
,	cteJobActivity AS (
		SELECT
			job_id
		,	start_execution_date
		,	stop_execution_date
		FROM msdb.dbo.sysjobactivity
		WHERE session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity)
	)
,   cteJobSummary AS (
    SELECT
        j.name AS [Job Name]
    ,   CASE j.enabled WHEN 1 THEN 'Enabled' ELSE 'Disabled' END AS [Job Status]
    ,   ISNULL(jsch.scheduled, 'No') AS [Is Scheduled]
    ,	CASE WHEN j.notify_level_email > 1 AND j.notify_email_operator_id > 0 THEN 'Yes' ELSE 'No' END AS [Email Notify on Fail]
    ,	CASE WHEN j.notify_level_eventlog > 1  THEN 'Yes' ELSE 'No' END AS [Event Log on Fail]
    ,   @periodStart AS [Period Start]
    ,   @periodEnd AS [Period End]
	,	ISNULL(NULLIF(CAST(FLOOR(AVG(jh.duration_seconds) / 86400) AS VARCHAR(10)), '0') +'d ', '')
		+ CONVERT(VARCHAR(10), DATEADD(SECOND, AVG(jh.duration_seconds), '19000101'), 8)
		AS [Average Run Time]
	,	ISNULL(NULLIF(CAST(FLOOR(MIN(jh.duration_seconds) / 86400) AS VARCHAR(10)), '0') +'d ', '')
		+ CONVERT(VARCHAR(10), DATEADD(SECOND, MIN(jh.duration_seconds), '19000101'), 8)
		AS [Shortest Run Time]
	,	ISNULL(NULLIF(CAST(FLOOR(MAX(jh.duration_seconds) / 86400) AS VARCHAR(10)), '0') +'d ', '')
		+ CONVERT(VARCHAR(10), DATEADD(SECOND, MAX(jh.duration_seconds), '19000101'), 8)
		AS [Longest Run Time]
    ,   SUM(CASE WHEN jh.run_status = 0 THEN 1 ELSE 0 END) AS [Failed Runs]
    ,   SUM(CASE WHEN jh.run_status = 1 THEN 1 ELSE 0 END) AS [Successful Runs]
    ,   SUM(CASE WHEN jh.run_status = 2 THEN 1 ELSE 0 END) AS [Retried Runs]
    ,   SUM(CASE WHEN jh.run_status = 3 THEN 1 ELSE 0 END) AS [Cancelled Runs]
    ,   msdb.dbo.agent_datetime(jlr.run_date, jlr.run_time) AS [Last Run]
    ,   jlr.last_run_status AS [Last Run Outcome]
	,	CASE
			WHEN ja.start_execution_date IS NOT NULL AND ja.stop_execution_date IS NULL
				THEN 
					 	ISNULL(NULLIF(CAST(FLOOR(DATEDIFF(second, ja.start_execution_date, GETDATE()) / 86400) AS VARCHAR(10)), '0') +'d ', '')
						+ CONVERT(VARCHAR(10), DATEADD(SECOND, DATEDIFF(second, ja.start_execution_date, GETDATE()), '19000101'), 8)
		END AS [Currently Running Duration]
    FROM
        msdb.dbo.sysjobs AS j
		LEFT JOIN cteJobActivity AS ja
			ON ja.job_id = j.job_id
        LEFT JOIN cteJobHistory AS jh
            ON jh.job_id = j.job_id
        LEFT JOIN cteJobLastRun AS jlr
            ON jlr.job_id = j.job_id
        LEFT JOIN cteJobSchedules AS jsch
            ON jsch.job_id = j.job_id
    WHERE 1=1
	    --and j.name LIKE 'Collect%' or j.name like 'DBAdmin%'
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
	,	ja.start_execution_date
	,	ja.stop_execution_date
    HAVING
        1=1
	    --and SUM(CASE WHEN jh.run_status = 0 THEN 1 ELSE 0 END) > 0 -- show failed jobs only
    --ORDER BY [Job Name]
)
SELECT
    *
FROM
    cteJobSummary
WHERE
	1=1
    AND ([Failed Runs] > 0 OR [Retried Runs] > 0)
    AND [Last Run Outcome] <> 'Success'
ORDER BY
    [Job Name]
;
