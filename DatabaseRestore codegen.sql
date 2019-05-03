/*
    Generate sp_DatabaseRestore commands for all user databases on an instance.

    The following conventions are assumed:

    1. Backups for the instance are stored in \\veeeam.ryanrts.com\database_backups\server[$instance]
    2. Backups were created using Ola Hallengren's Maintenance Solution with FULL, DIFF, and LOG backups
       in separate subfolders.
*/
DECLARE @backupfolder sysname = REPLACE(CAST(SERVERPROPERTY('ServerName') AS sysname), '\', '$')
DECLARE @backupdir nvarchar(255) = '\\veeam\database_backups\' + @backupfolder

--DECLARE @databaseName sysname = 'DBAdmin'
--DECLARE @restoreName sysname = 'CADNCETEST_copy'


DECLARE @fullPath nvarchar(255)
DECLARE @diffPath nvarchar(255)
DECLARE @logPath nvarchar(255) 

DECLARE @MoveDataPath nvarchar(255) = 'E:\MSSQL13.CADENCE\MSSQL\Data'
DECLARE @MoveLogPath nvarchar(255) = 'D:\MSSQL13.CADENCE\MSSQL\Data'

DECLARE @db sysname
DECLARE @sql NVARCHAR(MAX)

DECLARE cur_db CURSOR LOCAL FAST_FORWARD FOR
    SELECT name FROM sys.databases WHERE database_id > 4;
OPEN cur_db
FETCH NEXT FROM cur_db INTO @db

WHILE @@FETCH_STATUS = 0
BEGIN

    SET @fullPath = @backupdir + '\' + @db + '\FULL\'
    SET @diffPath = @backupdir + '\' + @db + '\DIFF\'
    SET @logPath = @backupdir + '\' + @db + '\LOG\'

    SET @sql = N'
    BEGIN TRY

        EXEC dbo.sp_DatabaseRestore 
        @Database = @databaseName, 
        @BackupPathFull = @fullPath, 
        @BackupPathDiff = @diffPath,
        @BackupPathLog = @logPath, 
        @RestoreDiff = 0,
        @ContinueLogs = 0,
        @RunRecovery = 1,
        @TestRestore = 0,
        @RunCheckDB = 0,
        @Debug = 0,
        --@RestoreDatabaseName = @restoreName,
        @MoveFiles = 1,
        @MoveDataDrive = @MoveDataPath,
        @MoveLogDrive = @MoveLogPath,
        @Execute = ''N'';

    END TRY
    BEGIN CATCH
        IF ERROR_MESSAGE() LIKE ''(LOG) No rows were returned for that database%''
            PRINT ''RESTORE DATABASE ''+QUOTENAME(@databaseName)+'' WITH RECOVERY;''
        ELSE
            THROW;
    END CATCH
    '
    print @sql
    EXEC sp_executesql
        @sql
    ,   N'@databaseName sysname, @fullPath nvarchar(255), @diffPath nvarchar(255), @logPath nvarchar(255),
         @MoveDataPath nvarchar(255), @MoveLogPath nvarchar(255)'
    ,   @databaseName = @db
    ,   @fullPath=@fullPath
    ,   @diffPath=@diffPath
    ,   @logPath=@logPath
    ,   @MoveDataPath=@MoveDataPath
    ,   @MoveLogPath=@MoveLogPath
    ;

    FETCH NEXT FROM cur_db INTO @db
END
CLOSE cur_db
DEALLOCATE cur_db

/*
EXEC dbo.sp_DatabaseRestore 
    @Database = @databaseName, 
    @BackupPathFull = @fullPath, 
    @BackupPathDiff = @diffPath,
    @BackupPathLog = @logPath, 
    @RestoreDiff = 1,
    @ContinueLogs = 0,
    @RunRecovery = 1,
    @TestRestore = 0,
    @RunCheckDB = 0,
    @Debug = 0,
    --@RestoreDatabaseName = @restoreName,
    @MoveFiles = 1,
    @MoveDataDrive = @MoveDataPath,
    @MoveLogDrive = @MoveLogPath,
    @Execute = 'N';
*/


--select name, physical_name from cadncedv3.sys.database_files