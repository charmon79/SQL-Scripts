USE WideWorldImporters;

SELECT s.Name AS SchemaName, 
       t.Name AS TableName, 
       p.rows AS Row_Count, 
       CAST(ROUND((SUM(a.used_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Row_Used_MB, 
	   CAST(ROUND((SUM(CASE WHEN p.index_id <= 1 THEN a.used_pages ELSE 0 END) / 128.00), 2) AS NUMERIC(36, 2)) AS Row_Data_MB,
       CAST(ROUND((SUM(CASE WHEN p.index_id > 1 THEN a.used_pages ELSE 0 END) / 128.00), 2) AS NUMERIC(36, 2)) AS Row_Index_MB, 
       CAST(ROUND((SUM(a.total_pages - a.used_pages)) / 128.00, 2) AS NUMERIC(36, 2)) AS Row_Unused_MB, 
       CAST(ROUND((SUM(a.total_pages) / 128.00), 2) AS NUMERIC(36, 2)) AS Row_Total_MB,
       CAST(ROUND((SUM(CASE WHEN a.type = 2 AND i.type < 3 THEN a.used_pages ELSE 0 END) / 128.00), 2) AS NUMERIC(36, 2)) AS LOB_Used_MB,
	   CAST(ROUND((SUM(CASE WHEN a.type = 2 THEN a.total_pages - a.used_pages ELSE 0 END) / 128.00), 2) AS NUMERIC(36, 2)) AS LOB_Unused_MB,
	   CAST(ROUND((SUM(CASE WHEN a.type = 2 THEN a.total_pages ELSE 0 END) / 128.00), 2) AS NUMERIC(36, 2)) AS LOB_Total_MB
FROM sys.tables t
     INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
     INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID
                                    AND i.index_id = p.index_id
     INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
     INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
GROUP BY t.Name, 
         s.Name, 
         p.Rows
ORDER BY s.Name, 
         t.Name;

select
	s.name AS SchemaName
,	t.name as TableName
,	i.name as IndexName
,	i.type
,	a.*
FROM sys.tables t
     INNER JOIN sys.indexes i ON t.OBJECT_ID = i.object_id
     INNER JOIN sys.partitions p ON i.object_id = p.OBJECT_ID
                                    AND i.index_id = p.index_id
     INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
     INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE
	i.type > 2

select top 100 * from sys.internal_tables