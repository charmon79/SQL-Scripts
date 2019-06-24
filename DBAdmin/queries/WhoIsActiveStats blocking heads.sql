SELECT
    collection_time
,   start_time
,   login_time
,   session_id
,   elapsed_time_s
,   blocked_session_count
,   database_name
,   host_name
,   program_name
,   sql_text
,   cpu
,   (tempdb_allocations * 8.0) / 1024 AS tempdb_alloc_total_mb
,   (tempdb_current * 8.0) / 1024 AS tempdb_alloc_current_mb
,   reads
,   used_memory
FROM dbadmin..WhoIsActiveStats
WHERE
    blocked_session_count > 0
    AND blocking_session_id is null
    AND elapsed_time_s > 10
order by collection_time desc, elapsed_time_s desc