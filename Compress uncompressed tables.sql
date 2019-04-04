/* script compression DDL for uncompressed tables */

SELECT
    s.name AS SchemaName
,   t.name AS TableName
,   [SQL] = 'RAISERROR(''Compressing table ' + + QUOTENAME(s.name) + '.' + QUOTENAME(t.name) + '...'',0,1) WITH NOWAIT;'+CHAR(13)+CHAR(10)
    + 'ALTER TABLE ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
    + ' REBUILD WITH (DATA_COMPRESSION = ROW);'+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)
    + 'ALTER INDEX ALL ON ' + QUOTENAME(s.name) + '.' + QUOTENAME(t.name)
    + ' REBUILD WITH (DATA_COMPRESSION = ROW);'+CHAR(13)+CHAR(10)+'GO'+CHAR(13)+CHAR(10)
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
