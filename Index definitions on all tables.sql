USE XcelWebReport_Prod;
GO

WITH
    cteIndexes AS (
    SELECT
        QUOTENAME(s.name)+'.'+QUOTENAME(o.name) AS ObjectName
    ,   QUOTENAME(i.name) AS IndexName
    ,   i.index_id
    ,   CASE WHEN i.index_id = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END AS IndexType
    ,   CASE i.is_unique WHEN 1 THEN 'UNIQUE' ELSE '' END AS IsUnique
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
        i.index_id > 0
        AND o.type = 'V'
)
SELECT
    DropSQL = 'DROP INDEX '+cte.IndexName+' ON '+cte.ObjectName+';'
,   CreateSQL = 'CREATE '+cte.IsUnique+' '+cte.IndexType+' INDEX '+cte.IndexName+' ON '+cte.ObjectName+' '+cte.IndexDef+';'
FROM
    cteIndexes AS cte
ORDER BY 
    cte.ObjectName
,   cte.index_id
;