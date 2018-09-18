-- databases which have at least 1 connection
SELECT
	*
FROM
	pg_stat_database
WHERE
	numbackends > 0
ORDER BY
	numbackends DESC;

-- how many connections in each state, and age of oldest in state
SELECT
	db.datname
,	db.numbackends
,	a.state
,	count(1) as count_in_state
,	NOW() - min(state_change) AS longest_in_state
FROM
	pg_stat_database db
	JOIN pg_stat_activity a ON a.datid = db.datid
WHERE 1=1
	AND a.state = 'idle'
	--AND db.datname = '17010'
GROUP BY
	db.datname
,	db.numbackends
,	a.state;