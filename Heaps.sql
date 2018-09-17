
SELECT
    s.name AS SchemaName
  , t.name AS TableName
FROM
    sys.tables AS t
    JOIN sys.schemas AS s
        ON s.schema_id = t.schema_id
    JOIN sys.indexes AS i
        ON i.object_id = t.object_id
WHERE i.index_id = 0 -- heap
;