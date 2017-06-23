if object_id('tempdb..#results') IS NOT NULL DROP TABLE #results;
CREATE TABLE #results (
    DatabaseName sysname
,   SchemaName sysname
,   ObjectName sysname
,   FTIndexedColumns NVARCHAR(MAX)
);

INSERT #results
    (
        DatabaseName
    ,   SchemaName
    ,   ObjectName
    ,   FTIndexedColumns
    )
EXEC sp_msforeachdb '
USE [?];
SET QUOTED_IDENTIFIER ON;
SELECT
    ''?''
,   s.name
,   o.name
,   STUFF( (SELECT '','' + c.name
               FROM sys.fulltext_index_columns AS fic
                    JOIN sys.columns AS c ON c.object_id = fic.object_id AND c.column_id = fic.column_id
               WHERE fic.object_id = fi.object_id
               ORDER BY c.name
               FOR XML PATH(''''), TYPE).value(''.'', ''varchar(max)'')
            ,1,1,'''') AS FTIndexedColumns
FROM
    sys.fulltext_indexes AS fi
    JOIN sys.objects AS o ON o.object_id = fi.object_id
    JOIN sys.schemas AS s ON s.schema_id = o.schema_id
';

SELECT * FROM #results AS r;

