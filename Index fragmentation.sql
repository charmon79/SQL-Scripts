

SELECT
    s.name AS SchemaName
  , o.name AS TableName
  , ind.name AS IndexName
  , indexstats.index_type_desc AS IndexType
  , indexstats.page_count
  , indexstats.avg_fragmentation_in_percent
FROM
    sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, NULL) AS indexstats
    INNER JOIN sys.indexes AS ind
        ON ind.object_id = indexstats.object_id
           AND ind.index_id = indexstats.index_id
    INNER JOIN sys.objects AS o
        ON o.object_id = ind.object_id
    INNER JOIN sys.schemas AS s
        ON s.schema_id = o.schema_id
WHERE
    1=1
    --and indexstats.avg_fragmentation_in_percent > 30
    and ind.type > 0
    and indexstats.page_count > 1000
ORDER BY
    indexstats.avg_fragmentation_in_percent DESC;