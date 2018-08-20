SELECT
    mf.type_desc
,   d.name
,   mf.name AS logical_name
,   mf.physical_name
,   d.state_desc
,   (mf.size * 8.0) / 1024.0 AS SizeMB
,   CASE mf.max_size
        WHEN -1
            THEN 'unlimited'
        ELSE CONVERT(VARCHAR(20), (mf.max_size * 8.0) / 1024)
    END AS MaxSizeMB
,   CASE
        WHEN mf.is_percent_growth = 1
            THEN CONVERT(VARCHAR(20), mf.growth) + '%'
        ELSE CONVERT(VARCHAR(20), (mf.growth * 8.0) / 1024.0) + ' MB'
    END AS Growth
,   d.recovery_model_desc
--,   'ALTER DATABASE '+quotename(d.name)+' MODIFY FILE (NAME = ' + quotename(mf.name) + ', FILEGROWTH = 1 GB);' AS [Change Growth 1 GB]
,   'ALTER DATABASE '+quotename(d.name)+' MODIFY FILE (NAME = ' + quotename(mf.name) + ', FILEGROWTH = 128 MB);' AS [Change Growth 128 MB]
FROM
    sys.master_files AS mf
    INNER JOIN sys.databases AS d
        ON d.database_id = mf.database_id
WHERE
    1 = 1
    --AND (d.state = 0 and mf.type = 0 AND (mf.growth < 131072 or mf.is_percent_growth = 1)) -- filegrowth not 1GB increment for data files
    --AND (d.state = 0 and mf.type = 1 AND (mf.growth < 16384 or mf.is_percent_growth = 1)) -- filegrowth is percent or < 128 MB increment for log files
ORDER BY
    d.name
,   mf.type
,   mf.name;

--select (128 * 1024) / 8
