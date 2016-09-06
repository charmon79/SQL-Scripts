USE XDB;
GO

DECLARE @dbid INT = DB_ID();

WITH cte_stats AS (
    SELECT	o.name AS procedure_name
         ,	eps.cached_time
         ,	eps.last_execution_time
         ,	eps.execution_count
         ,  CAST(eps.execution_count AS FLOAT) / COUNT(1) OVER() AS [weight]
         ,	eps.total_worker_time
         ,	eps.last_worker_time
         ,	eps.min_worker_time
         ,	eps.max_worker_time
	     ,	(eps.total_worker_time / eps.execution_count) AS avg_worker_time
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
         ,	eps.total_elapsed_time
         ,	eps.last_elapsed_time
         ,	eps.min_elapsed_time
         ,	eps.max_elapsed_time
	     ,	(eps.total_elapsed_time / eps.execution_count) AS avg_elapsed_time
    FROM	sys.objects o
		    INNER JOIN sys.dm_exec_procedure_stats eps ON eps.object_id = o.object_id AND eps.database_id = @dbid
		    LEFT JOIN sys.dm_exec_query_memory_grants qmg ON qmg.plan_handle = eps.plan_handle
)
SELECT  *
FROM    cte_stats
ORDER BY 
    --avg_worker_time DESC -- by CPU, weighted
    --avg_logical_reads * weight DESC -- by reads, weighted
    --avg_logical_writes DESC -- by writes, weighted
    avg_elapsed_time * weight DESC -- by time, weighted
