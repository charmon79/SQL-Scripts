USE servicedesk;
GO

SELECT
    s.name AS SchemaName
,   t.name AS TableName
,   usage.LastUpdated
,   usage.LastRead
FROM
    sys.tables t
    join sys.schemas s on s.schema_id = t.schema_id
    outer apply (
        select
            max(last_user_update) LastUpdated
        ,   max(coalesce(last_user_seek, last_user_scan)) LastRead
        from sys.dm_db_index_usage_stats ius
        where ius.database_id = db_id()
            and ius.object_id = t.object_id
    ) usage
WHERE
    t.is_ms_shipped = 0
ORDER BY
    --schemaname, tablename
    lastread desc
;
