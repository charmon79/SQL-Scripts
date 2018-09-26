

SELECT
	count(1) AS idle_blockers
FROM
	sys.dm_exec_sessions AS s
	JOIN sys.dm_os_waiting_tasks AS w ON w.blocking_session_id = s.session_id
WHERE
	s.status = 'sleeping'
	AND s.last_request_end_time <= DATEADD(minute, -1, getdate())
;
