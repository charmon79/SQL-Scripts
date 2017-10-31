SET NOCOUNT ON;

DECLARE @db sysname
    ,   @refdb sysname
    ,   @sql NVARCHAR(max)
;

DROP TABLE IF EXISTS #CrossDBReferences;
CREATE TABLE #CrossDBReferences (
    DatabaseName sysname NOT NULL
,   SchemaName sysname NOT NULL
,   ObjectName sysname NOT NULL
,   ReferencedDatabaseName sysname NOT NULL
);

/* for each database, look for objects with a reference to any of the OTHER database names on the instance */

DECLARE cur_db CURSOR LOCAL FAST_FORWARD FOR
	SELECT name FROM sys.databases WHERE database_id > 4;

OPEN cur_db;

FETCH NEXT FROM cur_db INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN    
    DECLARE cur_refdb CURSOR LOCAL FAST_FORWARD FOR
    	SELECT name FROM sys.databases WHERE database_id > 4 AND name <> @db
    
    OPEN cur_refdb;
    
    FETCH NEXT FROM cur_refdb INTO @refdb;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = 'SELECT
    '''+@db+''' AS DatabaseName
,   s.name AS SchemaName
,   o.name AS ObjectName
,   '''+@refdb+''' AS ReferencedDatabaseName
FROM
    '+QUOTENAME(@db)+'.sys.sql_modules AS sm
    JOIN '+QUOTENAME(@db)+'.sys.objects AS o ON o.object_id = sm.object_id
    JOIN '+QUOTENAME(@db)+'.sys.schemas AS s ON s.schema_id = o.schema_id
WHERE 1=1
    AND o.is_ms_shipped = 0
    AND sm.definition LIKE ''%'+@refdb+'%''
    AND '''+@db+''' NOT IN (''atlas_cdx'',''atlas_cdx_tenant'')
;'

    INSERT #CrossDBReferences
    EXEC (@sql)
    
        FETCH NEXT FROM cur_refdb INTO @refdb;
    END
    
    CLOSE cur_refdb;
    DEALLOCATE cur_refdb;

    FETCH NEXT FROM cur_db INTO @db;
END

CLOSE cur_db;
DEALLOCATE cur_db;


SELECT *
FROM #CrossDBReferences AS cdr