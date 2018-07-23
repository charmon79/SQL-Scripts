WITH files AS (
SELECT
	name
,	size
,	AVG(size) OVER() AS AvgSize
FROM
	tempdb.sys.database_files
WHERE
	type = 0 -- data files only
)
SELECT
	*
FROM
	files
WHERE
	size <> AvgSize
;