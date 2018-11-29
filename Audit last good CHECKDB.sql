
DROP TABLE IF EXISTS #DBCCResults;
CREATE TABLE #DBCCResults (
    ParentObject nvarchar(128)
,   Object nvarchar(128)
,   Field nvarchar(128)
,   Value nvarchar(128)
);

DROP TABLE IF EXISTS #Final;
CREATE TABLE #Final (
    DatabaseName sysname
,   Field nvarchar(128)
,   Value nvarchar(128)
);

DECLARE @db sysname, @sql nvarchar(max);

DECLARE cur_DB cursor local fast_forward for
    select name from sys.databases where name <> 'tempdb'

OPEN cur_DB
FETCH NEXT FROM cur_DB INTO @db

WHILE @@FETCH_STATUS = 0
BEGIN
    TRUNCATE TABLE #DBCCResults;
    SET @sql = N'DBCC DBINFO(@dbParm) WITH TABLERESULTS';

    INSERT #DBCCResults
    exec sp_executesql
        @sql
    ,   N'@dbParm sysname'
    ,   @dbParm = @db
    
    INSERT #Final
    SELECT a.DatabaseName, b.Field, b.Value
    FROM (SELECT @db AS DatabaseName) a OUTER APPLY (SELECT * FROM #DBCCResults WHERE Field = 'dbi_dbccLastKnownGood') b

    FETCH NEXT FROM cur_DB INTO @db
END
CLOSE cur_DB
DEALLOCATE cur_DB

SELECT * FROM #Final

