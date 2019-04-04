
WITH LastIndexUpdates AS (
SELECT
    s.name AS SchemaName
,   t.name AS TableName
,   i.index_id
,   i.name AS IndexName
,   ddius.last_user_update
,   ddius.last_system_update
,   ddius.last_user_seek
,   ddius.last_user_scan
,   ddius.last_user_lookup
FROM
    sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    LEFT JOIN sys.indexes AS i ON i.object_id = t.object_id
    LEFT JOIN sys.dm_db_index_usage_stats AS ddius ON ddius.index_id = i.index_id AND ddius.object_id = i.object_id AND ddius.database_id = DB_ID()
WHERE   1=1
    AND t.is_ms_shipped = 0
    --AND t.name LIKE @TablePattern
    --and t.name like '%aaron%'
--ORDER BY
--    COALESCE(ddius.last_user_update, ddius.last_system_update) DESC
)
,   TableSizes AS (
    SELECT
        *
    FROM
        DBAdmin.dbo.DatabaseTableSizes
    WHERE
        CollectedTime >= CAST(getdate() as date)
        AND DatabaseName = DB_NAME()
)
SELECT
    liu.SchemaName
,   liu.TableName
,   MAX(liu.last_user_update) AS last_user_update
,   MAX(liu.last_system_update) AS last_system_update
,   MAX(liu.last_user_seek) AS last_user_seek
,   MAX(liu.last_user_scan) AS last_user_scan
,   MAX(liu.last_user_lookup) AS last_user_lookup
,   ts.Rows
,   ts.DataMB
,   ts.IndexMB
,   ts.UnusedMB
FROM
    LastIndexUpdates AS liu
    JOIN TableSizes AS ts ON ts.SchemaName = liu.SchemaName AND ts.TableName = liu.TableName
WHERE
    last_user_scan > '2018-10-12'
GROUP BY liu.SchemaName
     ,   liu.TableName
     ,   ts.Rows
    ,   ts.DataMB
    ,   ts.IndexMB
    ,   ts.UnusedMB