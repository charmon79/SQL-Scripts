--DECLARE @backupdir nvarchar(255) = 'C:\SQLBackup\CHARMONVMWIN10\'
--DECLARE @backupdir nvarchar(255) = '\\veeam.ryanrts.com\database_backups\DWSQL01$CADENCE'
DECLARE @backupdir nvarchar(255) = '\\veeam\database_backups\ProdCadence20180212\PWCADSQL01$CADENCE'
DECLARE @databaseName sysname = 'CADNCETEST'
DECLARE @restoreName sysname = 'CADNCETEST_copy'


DECLARE @fullPath nvarchar(255) = @backupdir + '\' + @databaseName + '\FULL\'
DECLARE @diffPath nvarchar(255) = @backupdir + '\' + @databaseName + '\DIFF\'
DECLARE @logPath nvarchar(255) = @backupdir + '\' + @databaseName + '\LOG\'

DECLARE @MoveDataPath nvarchar(255) = 'E:\MSSQL13.CADENCE\MSSQL\Data'
DECLARE @MoveLogPath nvarchar(255) = 'D:\MSSQL13.CADENCE\MSSQL\Data'

--SELECT @fullpath, @diffPath, @logPath

EXEC dbo.sp_DatabaseRestore 
    @Database = @databaseName, 
    @BackupPathFull = @fullPath, 
    @BackupPathDiff = @diffPath,
    --@BackupPathLog = @logPath, 
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
    @Execute = 'N';


--select name, physical_name from cadncedv3.sys.database_files