USE XDB;

SELECT  o.name
      , deps.sql_handle
      , deps.plan_handle
      , deps.cached_time
      , deps.last_execution_time
      , deps.execution_count
      , deps.last_worker_time
      , deps.min_worker_time
      , deps.max_worker_time
      , deps.last_physical_reads
      , deps.min_physical_reads
      , deps.max_physical_reads
      , deps.last_logical_writes
      , deps.min_logical_writes
      , deps.max_logical_writes
      , deps.last_logical_reads
      , deps.min_logical_reads
      , deps.max_logical_reads
      , deps.last_elapsed_time
      , deps.min_elapsed_time
      , deps.max_elapsed_time
FROM sys.dm_exec_procedure_stats AS deps
INNER JOIN sys.objects AS o ON o.object_id = deps.object_id
WHERE o.name = 'MyQueue_SelectAgentsByUser'