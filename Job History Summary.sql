USE msdb;
GO

DECLARE @periodEnd DATETIME = GETDATE();
DECLARE @periodStart DATETIME = DATEADD(DAY, -1, @periodEnd);

WITH cteJobHistory AS (
SELECT
  s.job_id
, s.step_id
, s.run_status
, s.run_date
, s.run_time
, ((s.run_duration / 10000 * 3600 + (s.run_duration / 100) % 100 * 60 + s.run_duration % 100 ) ) AS duration_seconds
, CAST(CONCAT(
            s.run_duration / 10000 -- hours
        ,   ':'
        ,   (s.run_duration / 100) % 100 -- minutes
        ,   ':'
        ,   (s.run_duration % 100) -- seconds
        ) AS TIME(3)) AS duration_time
FROM dbo.sysjobhistory AS s
)
SELECT
    SJ.name AS [Job Name]
,   CASE sj.enabled WHEN 1 THEN 'Enabled' ELSE 'Disabled' END AS [Job Status]
,   @periodStart AS [Period Start]
,   @periodEnd AS [Period End]
,   CAST(DATEADD(ss, AVG(sjh.duration_seconds),0) AS TIME(3)) AS [Average Run Time]
,   MIN(SJH.duration_time) AS [Shortest Run Time]
,   MAX(SJH.duration_time) AS [Longest Run Time]
,   SUM(CASE WHEN SJH.run_status = 0 THEN 1 ELSE 0 END) AS [Failed Runs]
,   SUM(CASE WHEN SJH.run_status = 1 THEN 1 ELSE 0 END) AS [Successful Runs]
,   SUM(CASE WHEN SJH.run_status = 2 THEN 1 ELSE 0 END) AS [Retried Runs]
,   SUM(CASE WHEN SJH.run_status = 3 THEN 1 ELSE 0 END) AS [Cancelled Runs]
FROM
    cteJobHistory AS SJH
    JOIN dbo.sysjobs AS SJ
        ON SJH.job_id = SJ.job_id
WHERE
    SJH.step_id = 0
    AND dbo.agent_datetime(sjh.run_date, sjh.run_time) BETWEEN @periodStart AND @periodEnd
GROUP BY 
    sj.job_id
,   sj.name
,   sj.enabled
ORDER BY [Job Name]
;