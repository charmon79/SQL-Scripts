
SELECT
    ds.name AS FileGroupName
,   s.name AS SchemaName
,   t.name AS TableName
,   i.index_id AS IndexId
,   i.name AS IndexName
FROM
    sys.tables t
    join sys.schemas s ON s.schema_id = t.schema_id
    join sys.indexes i ON i.object_id = t.object_id
    join sys.data_spaces ds ON ds.data_space_id = i.data_space_id
WHERE
    ds.name IN (
        'dat3'
    ,   'idx1'
    ,   'idx3'
    ,   'txt2'
    )
ORDER BY
    ds.name
,   s.name
,   t.name
,   i.index_id
,   i.name