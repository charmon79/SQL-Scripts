WITH blockchain AS (
	-- blocking heads
	SELECT
		wt.blocking_session_id AS session_id
	,	CAST(NULL AS smallint) AS blocking_session_id
	,	CAST(NULL AS bigint) AS blocked_ms
	,	0 AS [Level]
	FROM
		sys.dm_os_waiting_tasks AS wt
	WHERE
		wt.blocking_session_id IS NOT NULL
		AND NOT EXISTS (
			SELECT 1
			FROM sys.dm_os_waiting_tasks AS wt2
			WHERE wt2.session_id = wt.blocking_session_id
		)

	UNION ALL

	-- blocking chain
	SELECT
		wt.session_id
	,	wt.blocking_session_id
	,	wt.wait_duration_ms AS blocked_ms
	,	b.[Level] + 1 AS [Level]
	FROM
		sys.dm_os_waiting_tasks wt
		JOIN blockchain b ON b.session_id = wt.blocking_session_id
	WHERE
		wt.blocking_session_id is not null
)
SELECT
	*
FROM blockchain;




