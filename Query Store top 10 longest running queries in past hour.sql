USE CADENCE;
GO

DECLARE @TopN int = 10

-- top 10 longest running queries in the past hour
SELECT
    --TOP 10
    qry.query_hash
,   txt.query_sql_text
,   pl.query_plan_hash
,   CAST(pl.query_plan AS XML) aS query_plan
,   qry.query_parameterization_type_desc
,   qry.last_execution_time
,   qry.avg_compile_duration
,   qrs.execution_type_desc
,   qrs.last_execution_time
,   qrs.count_executions
,   CAST(qrs.avg_duration / 1000000.0 AS decimal(18,4)) AS avg_duration_s
,   CAST(qrs.max_duration / 1000000.0 AS decimal(18,4)) AS max_duration_s
,   CAST(qrs.stdev_duration / 1000000.0 AS decimal(18,4)) AS stdev_duration_s
,   CAST(qrs.avg_cpu_time / 1000000.0 AS decimal(18,4)) AS avg_cpu_time_s
,   CAST(qrs.max_cpu_time / 1000000.0 AS decimal(18,4)) AS max_cpu_time_s
,   CAST(qrs.stdev_cpu_time / 1000000.0 AS decimal(18,4)) AS stdev_cpu_time_s
,   qrs.avg_logical_io_reads
,   qrs.max_logical_io_reads
,   qrs.stdev_logical_io_reads
,   qrs.avg_query_max_used_memory
,   qrs.max_query_max_used_memory
,   qrs.stdev_query_max_used_memory
,   qrs.avg_rowcount
,   qrs.max_rowcount
,   qrs.stdev_rowcount
,   qrs.avg_tempdb_space_used
,   qrs.max_tempdb_space_used
,   qrs.stdev_tempdb_space_used
FROM
    sys.query_store_plan AS pl
    JOIN sys.query_store_query AS qry ON qry.query_id = pl.query_id
    JOIN sys.query_store_query_text AS txt ON txt.query_text_id = qry.query_text_id
    JOIN (
        SELECT top (@TopN)
            rs.*
        FROM sys.query_store_runtime_stats_interval AS rsi
            JOIN sys.query_store_runtime_stats AS rs ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
        WHERE end_time >= DATEADD(hour, -1, GETDATE())
        ORDER BY avg_duration desc, stdev_duration desc
    ) AS qrs ON qrs.plan_id = pl.plan_id
;

-- top 10 most frequent queries in the past hour which took > 10ms
SELECT
    --TOP 10
    qry.query_hash
,   txt.query_sql_text
,   pl.query_plan_hash
,   CAST(pl.query_plan AS XML) aS query_plan
,   qry.query_parameterization_type_desc
,   qry.last_execution_time
,   qry.avg_compile_duration
,   qrs.execution_type_desc
,   qrs.last_execution_time
,   qrs.count_executions
,   CAST(qrs.avg_duration / 1000000.0 AS decimal(18,4)) AS avg_duration_s
,   CAST(qrs.max_duration / 1000000.0 AS decimal(18,4)) AS max_duration_s
,   CAST(qrs.stdev_duration / 1000000.0 AS decimal(18,4)) AS stdev_duration_s
,   CAST(qrs.avg_cpu_time / 1000000.0 AS decimal(18,4)) AS avg_cpu_time_s
,   CAST(qrs.max_cpu_time / 1000000.0 AS decimal(18,4)) AS max_cpu_time_s
,   CAST(qrs.stdev_cpu_time / 1000000.0 AS decimal(18,4)) AS stdev_cpu_time_s
,   qrs.avg_logical_io_reads
,   qrs.max_logical_io_reads
,   qrs.stdev_logical_io_reads
,   qrs.avg_query_max_used_memory
,   qrs.max_query_max_used_memory
,   qrs.stdev_query_max_used_memory
,   qrs.avg_rowcount
,   qrs.max_rowcount
,   qrs.stdev_rowcount
,   qrs.avg_tempdb_space_used
,   qrs.max_tempdb_space_used
,   qrs.stdev_tempdb_space_used
FROM
    sys.query_store_plan AS pl
    JOIN sys.query_store_query AS qry ON qry.query_id = pl.query_id
    JOIN sys.query_store_query_text AS txt ON txt.query_text_id = qry.query_text_id
    JOIN (
        SELECT top (@TopN)
            rs.*
        FROM sys.query_store_runtime_stats_interval AS rsi
            JOIN sys.query_store_runtime_stats AS rs ON rs.runtime_stats_interval_id = rsi.runtime_stats_interval_id
        WHERE end_time >= DATEADD(hour, -1, GETDATE())
            and rs.avg_duration > 10000
        ORDER BY count_executions DESC
    ) AS qrs ON qrs.plan_id = pl.plan_id
;