SELECT
	s.session_id
,	r.blocking_session_id
,	s.status
--,	t.transaction_id
,	t.open_transaction_count
--,	[at].transaction_state
,	r.total_elapsed_time / 1000.0 AS query_elapsed_time_s
,	r.wait_time / 1000.0 AS wait_time_s
,	r.last_wait_type
,	r.wait_resource
,	s.login_time
,	s.last_request_start_time
,	s.last_request_end_time
,	s.login_name
,   s.original_login_name
,	s.host_name
,	s.program_name
,	s.database_id
,	d.name AS database_name
--,	s.cpu_time AS cpu_time_total
--,	s.logical_reads AS logical_reads_total
--,	s.writes AS writes_total
,	s.memory_usage
,	r.cpu_time
,	r.logical_reads
,	r.writes
,	(r.granted_query_memory * 8.0) / 1024 AS granted_query_memory_mb
,	r.blocking_session_id
,	r.start_time AS query_start_time
,	r.command
,	r.sql_handle
,	r.plan_handle
,   'DBCC FREEPROCCACHE('+convert(varchar(128), r.plan_handle, 1)+')' AS plan_killer
,	st.text AS query_text
,	qp.query_plan
,   qs.query_hash
,   qs.query_plan_hash
,   qs.creation_time
,   qs.last_execution_time
,   qs.execution_count
,   (1.0 * qs.total_worker_time / qs.execution_count) AS avg_worker_time
,   qs.max_worker_time
,   (1.0 * qs.total_logical_reads / qs.execution_count) AS avg_logical_reads
,   qs.max_logical_reads
,   (1.0 * qs.total_elapsed_time / qs.execution_count) AS avg_elapsed_time
,   qs.max_elapsed_time
,   (qs.total_rows / qs.execution_count) AS avg_rows
,   qs.max_rows
,   qs.min_dop
,   qs.max_dop
,   (1.0 * qs.total_grant_kb / qs.execution_count) AS avg_grant_kb
,   qs.max_grant_kb
,   (1.0 * qs.total_ideal_grant_kb / qs.execution_count) AS avg_ideal_grant_kb
,   qs.max_ideal_grant_kb
,   (1.0 * qs.total_spills / qs.execution_count) AS avg_spills
,   qs.max_spills
FROM
	sys.dm_exec_sessions AS s
	LEFT JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
	LEFT JOIN sys.databases AS d ON d.database_id = s.database_id
	OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) AS st
	OUTER APPLY sys.dm_exec_query_plan(r.plan_handle) AS qp
    LEFT JOIN sys.dm_exec_query_stats AS qs ON qs.sql_handle = r.sql_handle
	LEFT JOIN sys.dm_tran_session_transactions AS t
		INNER JOIN sys.dm_tran_active_transactions AS [at] on [at].transaction_id = t.transaction_id
	ON t.session_id = s.session_id
WHERE
	s.session_id > 50
	and s.status <> 'sleeping'

order by
	--r.wait_time desc
    granted_query_memory_mb desc
;


