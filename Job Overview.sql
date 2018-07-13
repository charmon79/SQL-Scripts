SELECT
    j.name
,	j.description
,   j.enabled
,   CASE WHEN sch.schedule_id IS NOT NULL THEN 1 ELSE 0 END AS IsScheduled
,	msdb.dbo.agent_datetime(sch.next_run_date, sch.next_run_time) AS next_run_datetime
FROM
    msdb.dbo.sysjobs AS j
    OUTER APPLY (
        SELECT TOP 1
            *
        FROM
            msdb.dbo.sysjobschedules AS jsch
        WHERE
            jsch.job_id = j.job_id
            AND msdb.dbo.agent_datetime(NULLIF(jsch.next_run_date, 0), jsch.next_run_time) >= GETDATE()
        ORDER BY 
            jsch.next_run_date ASC, jsch.next_run_time ASC
    ) AS sch
ORDER BY
    j.name