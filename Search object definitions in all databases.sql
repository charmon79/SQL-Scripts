IF object_id('tempdb..#Results') IS NOT NULL DROP TABLE #Results;
CREATE TABLE #Results
(
    DatabaseName sysname NOT NULL
,   SchemaName sysname NOT NULL
,   ObjectName sysname NOT NULL
,   ObjectType NVARCHAR(60)
)

INSERT #Results
EXEC sp_msForeachdb 
    'USE [?];
    SELECT ''?'' AS DatabaseName
          , s.name AS SchemaName
          , o.name AS ObjectName
          , o.type_desc AS ObjectType
    FROM    XcelWeb_Prod.sys.sql_modules AS sm
            INNER JOIN XcelWeb_Prod.sys.objects AS o
                INNER JOIN XcelWeb_Prod.sys.schemas AS s ON s.schema_id = o.schema_id
                ON o.object_id = sm.object_id
    WHERE   sm.definition LIKE ''%http://cdx.xceligent.com%''
    ORDER BY o.type
          , o.name;'

SELECT *
FROM #Results;