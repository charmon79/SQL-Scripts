SELECT
    j.name
,	j.description
,   j.enabled
,   CASE WHEN sch.schedule_id IS NOT NULL THEN 1 ELSE 0 END AS IsScheduled
,	msdb.dbo.agent_datetime(sch.next_run_date, sch.next_run_time) AS next_run_datetime
,	sp.name AS owner
,	'exec msdb.dbo.sp_update_job
		@job_name = '''+j.name+'''
	,	@owner_login_name = @sa_name;' AS change_owner_sql

FROM
    msdb.dbo.sysjobs AS j
	LEFT JOIN sys.server_principals AS sp ON sp.sid = j.owner_sid
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
WHERE 1=1
	-- AND sp.principal_id is null -- owner login doesn't exist
	--AND j.owner_sid <> 0x01 -- 'sa' or renamed 'sa' account
ORDER BY
    j.name