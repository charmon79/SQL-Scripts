create table #results (
    DatabaseName sysname not null
,   SchemaName sysname not null
,   ObjectName sysname not null
,   ObjectType sysname not null
,   ObjectDefinition nvarchar(max)
);

SET NOCOUNT ON;

DECLARE @sql NVARCHAR(MAX);
DECLARE @db sysname;

DECLARE cur_db cursor local fast_forward for
    select name from sys.databases where state = 0;

OPEN cur_db;
FETCH NEXT FROM cur_db INTO @db;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = N'
USE '+quotename(@db)+N';
SELECT
    db_name()
,   s.name
,   o.name
,   o.type_desc
,   sm.definition
FROM
    sys.sql_modules sm
    JOIN sys.objects o on o.object_id = sm.object_id
    join sys.schemas s on s.schema_id = o.schema_id
WHERE
    sm.definition LIKE ''%PWMCLEODDB01.%''
    OR sm.definition LIKE ''%PWMCLEODDB01\]%'' ESCAPE ''\''
';

    INSERT #results
    EXEC(@sql);

    FETCH NEXT FROM cur_db INTO @db;

END;

CLOSE cur_db;
DEALLOCATE cur_db;

SELECT *
FROM #results;