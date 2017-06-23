WITH    DBFileSizes AS (
SELECT  d.name
    ,   mf.type_desc
    ,   mf.name AS logical_name
	,	UPPER(LEFT(mf.physical_name, 1)) AS drive_letter
    ,   mf.physical_name
	,   (mf.size * 8.0) / 1024.0 AS SizeMB
    ,   d.recovery_model_desc
FROM    sys.master_files AS mf
        INNER JOIN sys.databases AS d ON d.database_id = mf.database_id
)
SELECT
    SERVERPROPERTY('ServerName') AS ServerName
,   fs.type_desc
,   fs.drive_letter
,   SUM(fs.SizeMB) AS UsedMB
FROM    DBFileSizes AS fs
GROUP BY
    fs.type_desc
,   fs.drive_letter
;