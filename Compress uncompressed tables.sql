/* script compression DDL for uncompressed tables */

SELECT
    s.name AS SchemaName
,   t.name AS TableName
,   [SQL] = 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
    + ' REBUILD WITH (DATA_COMPRESSION = ROW)'
FROM sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
WHERE EXISTS (
    SELECT  *
    FROM    sys.partitions AS p
    WHERE   p.object_id = t.object_id
        AND p.index_id IN (1, 0)
        AND p.data_compression = 0 -- NONE
    )
ORDER BY s.name, t.name
;

SELECT TOP 100
    *
FROM sys.partitions AS p