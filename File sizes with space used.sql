SELECT
        d.name AS DatabaseName
    ,   mf.type
    ,   mf.type_desc
    ,   mf.name AS FileLogicalName
    ,   mf.physical_name AS FilePhysicalName
    ,   mf.size
    ,   (mf.size * 8.0) / 1048576 AS SizeGB
    ,   (FILEPROPERTY(mf.name, 'SpaceUsed') * 8.0) / 1048576 AS UsedGB
FROM    sys.master_files AS mf
        INNER JOIN sys.databases AS d ON d.database_id = mf.database_id
WHERE   1=1
    --AND mf.type = 1
    --AND mf.size > 128000
    AND d.name = 'CommercialSearchStage'
ORDER BY
        d.name
    ,   mf.type
    ,   mf.name
;


