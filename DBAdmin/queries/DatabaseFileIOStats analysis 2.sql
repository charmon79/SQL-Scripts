USE DBAdmin;
GO

SELECT
    MIN(PeriodStart) OVER() AS ReportPeriodStart
,   MAX(PeriodEnd) OVER() AS ReportPeriodEnd
,   PeriodStart
,   PeriodEnd
,   DatabaseName
,   FileName
,   Reads
,   BytesRead
,   (BytesRead / NULLIF(Reads, 0)) AS AvgBytesPerRead
,   AvgReadLatency_s
,   Writes
,   BytesWritten
,   (BytesWritten / NULLIF(Writes, 0)) AS AvgBytesPerWrite
,   AvgWriteLatency_s
,   DENSE_RANK() OVER (PARTITION BY DatabaseName, FileName ORDER BY Reads DESC) HeaviestReadPeriods
,   DENSE_RANK() OVER (PARTITION BY DatabaseName, FileName ORDER BY Writes DESC) HeaviestWritePeriods
,   DENSE_RANK() OVER (PARTITION BY DatabaseName, FileName ORDER BY AvgReadLatency_s DESC) SlowestReadPeriods
,   DENSE_RANK() OVER (PARTITION BY DatabaseName, FileName ORDER BY AvgWriteLatency_s DESC) SlowestWritePeriods
FROM
    dbo.DatabaseFileIOStats
WHERE
    PeriodStart >= DATEADD(hour, -2, getdate())
    AND FileName LIKE '%_log'
ORDER BY
    PeriodStart