SELECT *
FROM ##Activity_charmon
ORDER BY 
query_elapsed_time_s desc
--collection_time DESC
;

exec tempdb.sys.sp_spaceused '##Activity_charmon'

create index ix_rank on ##Activity_charmon (query_elapsed_time_s desc);

--drop table #temp

-- summary
WITH TopQueryFinder AS (
	SELECT
		a.collection_time
	,	a.query_text
	,	a.query_plan
	,	RANK() OVER (PARTITION BY a.collection_time ORDER BY a.query_elapsed_time_s DESC) AS LongestRunning
	FROM
		##Activity_charmon AS a
)
,	ActivitySummary AS (
	SELECT
		a.collection_time
	,	count(1) AS all_sessions
	,	sum(case when a.host_name = 'PWCADSQL01' THEN 0 ELSE 1 END) AS client_sessions
	,	sum(case when a.blocking_session_id = 0 then 0 else 1 end) AS blocked_sessions
	,	max(a.query_elapsed_time_s) AS longest_query_time_s
	,	max(a.wait_time_s) AS longest_wait_time_s
	FROM
		##Activity_charmon AS a
	GROUP BY
		a.collection_time
)
SELECT
	*
INTO #temp
FROM
	ActivitySummary AS a
	CROSS APPLY (
		SELECT TOP 1
			query_text
		,	query_plan
		FROM
			TopQueryFinder
		WHERE
			collection_time = a.collection_time
			AND LongestRunning = 1
	) TopQuery
ORDER BY
	collection_time desc

/*
	Summarize by hour
*/
;WITH hourly AS (
SELECT
	DATEADD(hour, DATEDIFF(hour, 0, a.collection_time ), 0) AS collection_hour
,	SUM(all_sessions) AS all_sessions
,	SUM(client_sessions) AS client_sessions
,	SUM(blocked_sessions) AS blocked_sessions
,	MAX(longest_query_time_s) AS longest_query_time_s
,	MAX(longest_wait_time_s) AS longest_wait_time_s
FROM
	#temp a
WHERE
	query_text NOT LIKE 'RESTORE%'
	AND query_text NOT LIKE 'BACKUP%'
GROUP BY
	DATEADD(hour, DATEDIFF(hour, 0, a.collection_time ), 0)
)
,	TopQueryFinder AS (
	SELECT
		DATEADD(hour, DATEDIFF(hour, 0, a.collection_time ), 0) AS collection_hour
	,	a.query_text
	,	a.query_plan
	,	RANK() OVER (PARTITION BY DATEADD(hour, DATEDIFF(hour, 0, a.collection_time ), 0) ORDER BY longest_query_time_s DESC) AS LongestRunning
	FROM
		#temp AS a
	WHERE
		query_text NOT LIKE 'RESTORE%'
		AND query_text NOT LIKE 'BACKUP%'
)
SELECT
	*
FROM
	hourly h
	CROSS APPLY (
		SELECT TOP 1
			query_text
		,	query_plan
		FROM
			TopQueryFinder
		WHERE
			collection_hour = h.collection_hour
			AND LongestRunning = 1
	) TopQuery


select * from ##WaitStats_charmon order by PeriodStart desc, percentage desc

--DROP TABLE ##WaitStats_charmon;
--DROP TABLE ##Activity_charmon;