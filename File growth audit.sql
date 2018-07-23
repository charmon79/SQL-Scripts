/* Files with percent growth or too small an increment. */
SELECT
	d.name AS database_name
,	mf.name
,	CAST(CAST((mf.size * 8.0) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB' AS Size
,   CASE mf.max_size
        WHEN-1
            THEN 'unlimited'
        ELSE CAST(CAST((mf.max_size * 8.0) / 1024 AS DECIMAL(10,2)) AS VARCHAR(20))
    END AS MaxSizeMB
,   CASE
        WHEN mf.is_percent_growth = 1
            THEN CAST(mf.growth AS VARCHAR(20)) + '%'
        ELSE CAST(CAST((mf.growth * 8.0) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB'
    END AS Growth
,	'Percent autogrowth'
FROM
	sys.master_files aS mf
	join sys.databases as d on d.database_id = mf.database_id
WHERE
	mf.type in (0,1)
	AND d.name NOT IN ('master','msdb')
	AND is_percent_growth = 1

UNION ALL
SELECT
	d.name AS database_name
,	mf.name
,	CAST(CAST((mf.size * 8.0) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB' AS Size
,   CASE mf.max_size
        WHEN-1
            THEN 'unlimited'
        ELSE CAST(CAST((mf.max_size * 8.0) / 1024 AS DECIMAL(10,2)) AS VARCHAR(20))
    END AS MaxSizeMB
,   CASE
        WHEN mf.is_percent_growth = 1
            THEN CAST(mf.growth AS VARCHAR(20)) + '%'
        ELSE CAST(CAST((mf.growth * 8.0) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB'
    END AS Growth
,	'Too small autogrowth (< 128 MB)'
FROM
	sys.master_files aS mf
	join sys.databases as d on d.database_id = mf.database_id
WHERE
	mf.type in (0,1)
	AND mf.is_percent_growth = 0
	AND d.name NOT IN ('master','msdb')
	AND (d.name = 'tempdb' or mf.size > (64 * 1024) / 8) -- exclude small databases, but not tempdb
	AND mf.growth <= (128 * 1024) / 8 -- for a database of any real size, grow more than 128MB at once

UNION ALL
/* Files with too large an autogrow increment (> 1 GB) */
SELECT
	d.name AS database_name
,	mf.name
,	CAST(CAST((mf.size * 8.0) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB' AS Size
,   CASE mf.max_size
        WHEN-1
            THEN 'unlimited'
        ELSE CAST(CAST((mf.max_size * 8.0) / 1024 AS DECIMAL(10,2)) AS VARCHAR(20))
    END AS MaxSizeMB
,   CASE
        WHEN mf.is_percent_growth = 1
            THEN CAST(mf.growth AS VARCHAR(20)) + '%'
        ELSE CAST(CAST((mf.growth * 8.0) / 1024.0 AS DECIMAL(10,2)) AS VARCHAR(20)) + ' MB'
    END AS Growth
,	'Too large autogrowth (> 1 GB)'
FROM
	sys.master_files aS mf
	join sys.databases as d on d.database_id = mf.database_id
WHERE
	mf.type in (0,1)
	AND mf.is_percent_growth = 0
	AND d.name NOT IN ('master','msdb')
	AND mf.growth > (1024 * 1024) / 8 -- less than 128MB growth increment
;