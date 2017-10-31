USE Atlas_CDX;
GO

DECLARE @dbid INT = DB_ID();

WITH cte_stats AS (
    SELECT	o.name AS procedure_name
         ,	eps.cached_time
         ,	eps.last_execution_time
         ,	eps.execution_count
         ,  CAST(eps.execution_count AS FLOAT) / COUNT(1) OVER() AS [weight]
         ,	eps.total_worker_time / 1000000.0 AS total_worker_time_sec
         ,	eps.last_worker_time / 1000000.0 AS last_worker_time_sec
         ,	eps.min_worker_time / 1000000.0 AS min_worker_time_sec
         ,	eps.max_worker_time / 1000000.0 AS max_worker_time_sec
	     ,	(eps.total_worker_time * 1.0 / eps.execution_count) / 1000000.0 AS avg_worker_time_sec
         ,	eps.total_physical_reads
         ,	eps.last_physical_reads
         ,	eps.min_physical_reads
         ,	eps.max_physical_reads
	     ,	(eps.total_physical_reads / eps.execution_count) AS avg_physical_reads
         ,	eps.total_logical_writes
         ,	eps.last_logical_writes
         ,	eps.min_logical_writes
         ,	eps.max_logical_writes
	     ,	(eps.total_logical_writes / eps.execution_count) AS avg_logical_writes
         ,	eps.total_logical_reads
         ,	eps.last_logical_reads
         ,	eps.min_logical_reads
         ,	eps.max_logical_reads
	     ,	(eps.total_logical_reads / eps.execution_count) AS avg_logical_reads
         ,	eps.total_elapsed_time / 1000000.0 AS total_elapsed_time_sec
         ,	eps.last_elapsed_time / 1000000.0 AS last_elapsed_time_sec
         ,	eps.min_elapsed_time / 1000000.0 AS min_elapsed_time_sec
         ,	eps.max_elapsed_time / 1000000.0 AS max_elapsed_time_sec
	     ,	(eps.total_elapsed_time / eps.execution_count) / 1000000.0 AS avg_elapsed_time_sec
         ,  qp.query_plan
    FROM	sys.objects o
		    INNER JOIN sys.dm_exec_procedure_stats eps ON eps.object_id = o.object_id AND eps.database_id = @dbid
		    OUTER APPLY sys.dm_exec_query_plan(eps.plan_handle) AS qp
            LEFT JOIN sys.dm_exec_query_memory_grants qmg ON qmg.plan_handle = eps.plan_handle
            
)
SELECT  *
FROM    cte_stats
ORDER BY 
    --avg_worker_time DESC -- by CPU, weighted
    --avg_logical_reads * weight DESC -- by reads, weighted
    --avg_logical_writes DESC -- by writes, weighted
    avg_elapsed_time_sec * weight DESC -- by time, weighted
