USE tempdb;

SELECT
        DB_NAME() AS DatabaseName
    ,   df.type
    ,   df.type_desc
    ,   df.name AS FileLogicalName
    ,   df.physical_name AS FilePhysicalName
    ,   df.size
    ,   (df.size * 8.0) / 1048576 AS SizeGB
    ,   (FILEPROPERTY(df.name, 'SpaceUsed') * 8.0) / 1048576 AS UsedGB
	,	df.growth
	,	df.is_percent_growth
FROM    sys.database_files AS df
WHERE   1=1
    --AND df.type = 1
    --AND df.size > 128000
ORDER BY
        df.type
    ,   df.name
;
