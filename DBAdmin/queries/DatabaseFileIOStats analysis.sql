USE DBAdmin;
GO

WITH IOStats AS (
	SELECT
		PeriodStart
	,	PeriodEnd
	,	DatabaseName
	,	FileName
	,	Reads
	,	CAST(100 * (1.0 * Reads / (Reads + Writes)) AS DECIMAL(5,2)) AS ReadPercent
	,	AvgReadLatency_s
	,	Writes
	,	CAST(100 * (1.0 * Writes / (Reads + Writes)) AS DECIMAL(5,2)) AS WritePercent
	,	AvgWriteLatency_s
	,	AvgOverallLatency_s
	,	DENSE_RANK() OVER (PARTITION BY PeriodStart ORDER BY AvgWriteLatency_s DESC) AS SlowestWritesRank
	,	DENSE_RANK() OVER (PARTITION BY PeriodStart ORDER BY AvgReadLatency_s DESC) AS SlowestReadsRank
	,	DENSE_RANK() OVER (PARTITION BY PeriodStart ORDER BY AvgOverallLatency_s DESC) AS SlowestOverallRank
	FROM
		dbo.DatabaseFileIOStats
	WHERE
		PeriodStart >= DATEADD(hour, -6, GETDATE())
)
SELECT
	*
FROM
	IOStats
WHERE 1=1
	--AND SlowestReadsRank <= 10 -- top 10 files with slowest reads in each period
	--AND SlowestWritesRank <= 10 -- top 10 files with slowest writes in each period
	AND SlowestOverallRank <= 10 -- top 10 files with overall slowest I/O (reads and writes)
ORDER BY
	PeriodStart DESC
;