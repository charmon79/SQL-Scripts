SET NOCOUNT ON;

DECLARE @server sysname;
DECLARE @db sysname;
DECLARE @sql nvarchar(max);

DROP TABLE IF EXISTS #results;
CREATE TABLE #results (
    ServerName sysname
,   DatabaseName sysname
,   SchemaName sysname
,   ObjectName sysname
,   ObjectType nvarchar(256)
,   ObjectDefinition nvarchar(max)
);

/*
    For each server in sys.servers, look for references within SQL modules in each db.
    
    Specifically NOT filtering only for linked servers here, because we also want to see
    if there are 4-part-name references to things on the local SQL Server instance.    
*/
DECLARE cur_servers CURSOR LOCAL FAST_FORWARD FOR
    SELECT name
    FROM sys.servers;

OPEN cur_servers;
FETCH NEXT FROM cur_servers INTO @server;

WHILE @@FETCH_STATUS = 0
BEGIN
    /* for each database, search sys.sql_modules for 4-part-name references to server @server */
    DECLARE cur_dbs CURSOR LOCAL FAST_FORWARD FOR
        SELECT name FROM sys.databases WHERE database_id > 4 and name not in ('DBAdmin');
    OPEN cur_dbs;
    FETCH NEXT FROM cur_dbs INTO @db;
    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql = N'
            USE '+quotename(@db)+';
            SELECT  '''+@server+'''
                ,   db_name()
                ,   s.name
                ,   o.name
                ,   o.type_desc
                ,   sm.definition
            FROM sys.sql_modules sm
            JOIN sys.objects o ON o.object_id = sm.object_id
            JOIN sys.schemas s ON s.schema_id = o.schema_id
            WHERE sm.definition LIKE ''%'+@server+'.%'' OR sm.definition LIKE ''%|['+@server+'|]%'' ESCAPE ''|'';
        ';

        --print @sql;
        INSERT #results
        EXEC(@sql);

        FETCH NEXT FROM cur_dbs INTO @db;
    END
    CLOSE cur_dbs;
    DEALLOCATE cur_dbs;
    
    FETCH NEXT FROM cur_servers INTO @server;
END

CLOSE cur_servers;
DEALLOCATE cur_servers;

/* display results */
SELECT * FROM #results;