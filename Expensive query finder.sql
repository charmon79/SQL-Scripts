SELECT top 50
    sql_handle
,   plan_handle
,   query_hash
,   query_plan_hash
,   creation_time
,   last_execution_time
,   execution_count
,   (1.0 * total_worker_time / execution_count) AS avg_worker_time
,   max_worker_time
,   (1.0 * total_logical_reads / execution_count) AS avg_logical_reads
,   max_logical_reads
,   (1.0 * total_elapsed_time / execution_count) AS avg_elapsed_time
,   max_elapsed_time
,   (total_rows / execution_count) AS avg_rows
,   max_rows
,   min_dop
,   max_dop
,   (1.0 * total_grant_kb / execution_count) AS avg_grant_kb
,   max_grant_kb
,   (1.0 * total_ideal_grant_kb / execution_count) AS avg_ideal_grant_kb
,   max_ideal_grant_kb
,   (1.0 * total_spills / execution_count) AS avg_spills
,   max_spills
FROM
    sys.dm_exec_query_stats
    WHERE max_grant_kb > 1000000
ORDER BY
    max_grant_kb DESC
    --max_used_grant_kb desc

