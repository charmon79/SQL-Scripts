USE DBAdmin;
GO

WITH TopSessionsByTime AS (
	SELECT
		DATEADD(hour, DATEDIFF(hour, 0, collection_time), 0) AS TimeFrame
	,	'Top 10 by time' AS Category
	,	*
	,	ROW_NUMBER() OVER (PARTITION BY DATEADD(hour, DATEDIFF(hour, 0, collection_time), 0) ORDER BY elapsed_time_s DESC) AS SessionRank
	FROM
		dbo.WhoIsActiveStats
	WHERE
		1=1
		AND [program_name] not like 'SQLAgent -%' -- ignore agent jobs
)
SELECT
	*
FROM
	TopSessionsByTime
WHERE
	SessionRank <= 10
;

WITH TopSessionsByReads AS (
	SELECT
		DATEADD(hour, DATEDIFF(hour, 0, collection_time), 0) AS TimeFrame
	,	'Top 10 by reads' AS Category
	,	*
	,	ROW_NUMBER() OVER (PARTITION BY DATEADD(hour, DATEDIFF(hour, 0, collection_time), 0) ORDER BY reads DESC) AS SessionRank
	FROM
		dbo.WhoIsActiveStats
	WHERE
		1=1
		AND [program_name] not like 'SQLAgent -%' -- ignore agent jobs
)
SELECT
	*
FROM
	TopSessionsByReads
WHERE
	SessionRank <= 10
;