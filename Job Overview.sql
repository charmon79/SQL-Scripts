SELECT
    j.name
,   j.enabled
--,   jsch.*
,   CASE WHEN sch.schedule_id IS NOT NULL THEN 1 ELSE 0 END AS IsScheduled
FROM
    msdb.dbo.sysjobs AS j
    --LEFT JOIN msdb.dbo.sysjobschedules AS jsch ON jsch.job_id = j.job_id
    OUTER APPLY (
        SELECT TOP 1
            *
        FROM
            msdb.dbo.sysjobschedules AS jsch
        WHERE
            jsch.job_id = j.job_id
            --AND jsch.next_run_date >= CONVERT(INT, REPLACE(LEFT(CONVERT(VARCHAR(30), GETDATE(), 120), 10),'-',''))
            --AND jsch.next_run_time >= CONVERT(INT, REPLACE(RIGHT(CONVERT(VARCHAR(30), GETDATE(), 120), 8),':',''))
            AND msdb.dbo.agent_datetime(NULLIF(jsch.next_run_date, 0), jsch.next_run_time) >= GETDATE()
        ORDER BY 
            jsch.next_run_date ASC, jsch.next_run_time ASC
    ) AS sch
ORDER BY
    j.name