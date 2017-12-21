USE XcelWeb_Tenant;

DECLARE @TablePattern NVARCHAR(128) = 'tenant%';

WITH LastIndexUpdates AS (
SELECT
    s.name AS SchemaName
,   t.name AS TableName
,   i.index_id
,   i.name AS IndexName
,   ddius.last_user_update
,   ddius.last_system_update
FROM
    sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    LEFT JOIN sys.indexes AS i ON i.object_id = t.object_id
    LEFT JOIN sys.dm_db_index_usage_stats AS ddius ON ddius.index_id = i.index_id AND ddius.object_id = i.object_id AND ddius.database_id = DB_ID()
WHERE   
    t.name LIKE @TablePattern
--ORDER BY
--    COALESCE(ddius.last_user_update, ddius.last_system_update) DESC
)
SELECT
    SchemaName
,   TableName
,   MAX(liu.last_user_update) AS last_user_update
,   MAX(liu.last_system_update) AS last_system_update
FROM
    LastIndexUpdates AS liu
GROUP BY liu.SchemaName
     ,   liu.TableName;