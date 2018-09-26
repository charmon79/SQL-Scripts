USE CADNCEPRD;
GO

WITH
    cteIndexes AS (
    SELECT
        QUOTENAME(s.name)+'.'+QUOTENAME(o.name) AS ObjectName
    ,   QUOTENAME(i.name) AS IndexName
    ,   i.index_id
    ,   CASE WHEN i.index_id = 1 THEN 'CLUSTERED' ELSE 'NONCLUSTERED' END AS IndexType
    ,   i.is_unique AS IsUnique
    ,   CASE i.is_unique WHEN 1 THEN 'UNIQUE' ELSE '' END AS UniqueSQL
    ,   CASE
            WHEN ius.user_updates > 1 AND (ius.user_seeks + ius.user_scans + ius.user_lookups) = 0 THEN 0
            ELSE 1
        END AS IsUsed
    ,   ius.user_updates AS UserUpdates
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
        JOIN sys.dm_db_index_usage_stats AS ius ON ius.object_id = i.object_id AND ius.index_id = i.index_id
    WHERE
        o.is_ms_shipped = 0
        AND i.index_id > 0
)
SELECT
    ObjectName
,   IndexName
,   IndexType
,   IsUnique
,   IsUsed
,   UserUpdates
,   DisableSQL = 'ALTER INDEX '+cte.IndexName+' ON '+cte.ObjectName+' DISABLE;'
,   DropSQL = 'DROP INDEX '+cte.IndexName+' ON '+cte.ObjectName+';'
,   CreateSQL = 'CREATE '+cte.UniqueSQL+' '+cte.IndexType+' INDEX '+cte.IndexName+' ON '+cte.ObjectName+' '+cte.IndexDef+';'
FROM
    cteIndexes AS cte
WHERE
    IndexType = 'NONCLUSTERED' AND IsUsed = 0
    and IsUnique = 0 -- avoid disabling nonclustered PKs by mistake
ORDER BY 
    cte.ObjectName
,   cte.index_id
;