SELECT  mf.type_desc
    ,   d.name
    ,   mf.name AS logical_name
    ,   mf.physical_name
    ,   d.state_desc
    ,   (mf.size * 8.0) / 1024.0 AS SizeMB
    ,   CASE mf.max_size WHEN -1 THEN 'unlimited' ELSE LTRIM(STR((mf.max_size * 8.0) / 1024 )) END AS MaxSizeMB
    ,   CASE WHEN mf.is_percent_growth = 1
             THEN CONCAT(mf.growth, '%')
             ELSE CONCAT(LTRIM(STR((mf.growth * 8.0) / 1024.0)), ' MB')
        END AS Growth
    ,   d.recovery_model_desc
FROM    sys.master_files AS mf
        INNER JOIN sys.databases AS d ON d.database_id = mf.database_id
WHERE   d.name LIKE 'xdb%'
ORDER BY d.name, mf.type, mf.name
