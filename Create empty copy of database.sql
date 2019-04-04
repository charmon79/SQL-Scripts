DECLARE @databaseName sysname
    ,   @newDatabaseName sysname
    ,   @filegroupID INT
    ,   @filegroupName sysname
    ,   @fileLogicalName sysname
    ,   @fileNameNoExt NVARCHAR(255)
    ,   @fileExt NVARCHAR(16)
    ,   @datestamp NCHAR(8) = REPLACE(CAST(GETDATE() AS DATE), '-', '')
    ,   @sql NVARCHAR(MAX)
    ,   @crlf NCHAR(2) = CHAR(13)+CHAR(10)
;

SET @databaseName = DB_NAME();
SET @newDatabaseName = @databaseName + '_TEST';

-- root SQL for CREATE DATABASE
SET @sql = 'USE master' + @crlf + 'GO' + @crlf
+ 'IF DB_ID(''' + @newDatabaseName + ''') IS NOT NULL DROP DATABASE ' + QUOTENAME(@newDatabaseName) + @crlf + 'GO' + @crlf
+ 'CREATE DATABASE ' + QUOTENAME(@newDatabaseName) + ' ON' + @crlf;

-- iterate through filegroups
DECLARE cur_Filegroups CURSOR LOCAL FAST_FORWARD FOR
	SELECT  f.data_space_id, f.name
    FROM    sys.filegroups AS f;

OPEN cur_Filegroups;

FETCH NEXT FROM cur_Filegroups INTO @filegroupID, @filegroupName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql += CASE @filegroupName WHEN 'PRIMARY' THEN @filegroupName ELSE 'FILEGROUP ' + @filegroupName END + @crlf;

    -- iterate through database files to script filespec for each
    DECLARE cur_DataFiles CURSOR LOCAL FAST_FORWARD FOR
        SELECT  df.name
            ,   FileNameNoExt = REVERSE(SUBSTRING(REVERSE(df.physical_name), CHARINDEX('.', REVERSE(df.physical_name)) + 1, LEN(df.physical_name)))
            ,   FileExt = REVERSE(SUBSTRING(REVERSE(df.physical_name), 1, CHARINDEX('.', REVERSE(df.physical_name))))
        FROM    sys.database_files AS df
        WHERE   df.data_space_id = @filegroupID
        ;

    OPEN cur_DataFiles;

    FETCH NEXT FROM cur_DataFiles INTO @fileLogicalName, @fileNameNoExt, @fileExt;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        SET @sql += '  (NAME = ' + QUOTENAME(@fileLogicalName)
                    + ', FILENAME = ''' + @fileNameNoExt + '_TEST_' + @datestamp + @fileExt + ''''
                    + ', SIZE = 64 MB, FILEGROWTH = 64 MB)' + @crlf

        SET @sql += ',' -- in case there are additional files

        FETCH NEXT FROM cur_DataFiles INTO @fileLogicalName, @fileNameNoExt, @fileExt;
    END

    IF RIGHT(@sql, 1) = ',' SET @sql = LEFT(@sql, LEN(@sql) - 1); -- strip trailing comma

    CLOSE cur_DataFiles;
    DEALLOCATE cur_DataFiles;

    SET @sql += ',' -- in case there are additional filegroups

    FETCH NEXT FROM cur_Filegroups INTO @filegroupID, @filegroupName;
END

IF RIGHT(@sql, 1) = ',' SET @sql = LEFT(@sql, LEN(@sql) - 1); -- strip trailing comma

CLOSE cur_Filegroups;
DEALLOCATE cur_Filegroups;

SET @sql += 'LOG ON' + @crlf
         + (SELECT TOP 1
                '(NAME = ' + QUOTENAME(df.name) + ', FILENAME = '''
                    + REVERSE(SUBSTRING(REVERSE(df.physical_name), CHARINDEX('.', REVERSE(df.physical_name)) + 1, LEN(df.physical_name)))
                    + '_TEST_' + @datestamp + '.ldf'', SIZE = 64 MB, FILEGROWTH = 64 MB)'
            FROM sys.database_files AS df WHERE df.type = 1)
         + @crlf + 'GO' + @crlf;

IF EXISTS (
    SELECT 1
    FROM sys.change_tracking_databases AS ctd
    WHERE ctd.database_id = DB_ID(@databaseName)
)
    SET @sql += 'ALTER DATABASE ' + QUOTENAME(@newDatabaseName) + ' SET CHANGE_TRACKING = ON ('
                + (
                    SELECT
                          'CHANGE_RETENTION = ' + CAST(ctd.retention_period AS VARCHAR) + ' ' + ctd.retention_period_units_desc
                        + ', AUTO_CLEANUP = ' + CASE ctd.is_auto_cleanup_on WHEN 1 THEN 'ON' ELSE 'OFF' END
                    FROM sys.change_tracking_databases AS ctd
                    WHERE ctd.database_id = DB_ID(@databaseName)
                )
                + ');' + @crlf + 'GO' + @crlf

PRINT @sql

