with cte as (
SELECT
	s.session_id
,	s.status
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
,	s.memory_usage
,	r.cpu_time
,	r.logical_reads
,	r.writes
,	(r.granted_query_memory * 8.0) / 1024 AS granted_query_memory_mb
,	r.blocking_session_id
,	r.start_time AS query_start_time
FROM
	sys.dm_exec_sessions AS s
	LEFT JOIN sys.dm_exec_requests AS r ON r.session_id = s.session_id
WHERE
	s.session_id > 50
	--and s.status <> 'sleeping'
)
select
    status
,   count(1) as [count]
,   max(login_time) as newest
,   min(login_time) as oldest
from cte
group by status
