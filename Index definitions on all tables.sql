USE XcelWebReport_Prod;
GO

SELECT
    QUOTENAME(s.name)+'.'+QUOTENAME(o.name) AS ObjectName
,   i.name AS IndexName
,   IndexDef = '(' + STUFF( (SELECT ',' + c.name 
               FROM sys.index_columns AS ic
                    JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
               WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                AND ic.is_included_column = 0
               ORDER BY ic.index_column_id
               FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
            ,1,1,'')
    + ')' + ISNULL(' INCLUDE (' + STUFF( (SELECT ',' + c.name 
               FROM sys.index_columns AS ic
                    JOIN sys.columns AS c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
               WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
                AND ic.is_included_column = 1
               ORDER BY ic.index_column_id
               FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
            ,1,1,''),'') + ')'
FROM
    sys.objects AS o
    JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    JOIN sys.indexes AS i ON i.object_id = o.object_id
WHERE
    i.index_id > 1 -- nonclustered only
ORDER BY 
    ObjectName
,   IndexName

