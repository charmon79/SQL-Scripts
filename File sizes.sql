SELECT  name
    ,   mf.physical_name
    ,   mf.size
    ,   (size * 8) / 1024 AS size_mb
    ,   mf.max_size
    ,   mf.growth
    ,   mf.is_percent_growth
FROM sys.master_files AS mf
WHERE mf.database_id = 2