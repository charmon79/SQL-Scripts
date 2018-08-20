USE LME;

SELECT
        DB_NAME() AS DatabaseName
    ,   df.type
    ,   df.type_desc
    ,   df.name AS FileLogicalName
    ,   df.physical_name AS FilePhysicalName
    ,   df.size
    ,   (df.size * 8.0) / 1048576 AS SizeGB
    ,   (FILEPROPERTY(df.name, 'SpaceUsed') * 8.0) / 1048576 AS UsedGB
    ,   CAST(100 * ((1.0 * df.size - (FILEPROPERTY(df.name, 'SpaceUsed')) ) / df.size) AS DECIMAL(5,2)) AS PercentFree
    ,   CASE
            WHEN df.is_percent_growth = 1
                THEN CONVERT(VARCHAR(20), df.growth) + '%'
            ELSE CONVERT(VARCHAR(20), (df.growth * 8.0) / 1024.0) + ' MB'
        END AS Growth
    --,   'ALTER DATABASE LME MODIFY FILE (NAME = ' + quotename(df.name) + ', FILEGROWTH = 1 GB);' AS [Change Growth SQL]
FROM    sys.database_files AS df
WHERE   1=1
    --AND df.type = 1
    --AND df.size > 128000
ORDER BY
        df.type
    ,   df.name
;
