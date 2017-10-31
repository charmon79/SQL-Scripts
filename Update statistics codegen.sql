
SELECT 'RAISERROR(''Updating stats on '+QUOTENAME(s.name)+'.'+QUOTENAME(o.name)+''',0,1) WITH NOWAIT;
GO
UPDATE STATISTICS '+QUOTENAME(s.name)+'.'+QUOTENAME(o.name)+';
GO'
FROM sys.tables AS o
JOIN sys.schemas AS s ON s.schema_id = o.schema_id
WHERE o.is_ms_shipped = 0
AND s.name = 'dbo'