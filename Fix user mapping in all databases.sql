SET NOCOUNT ON;

DECLARE
    @sql_AU NVARCHAR(MAX)
  , @sql_db NVARCHAR(200)
  , @sql_name VARCHAR(200)
  , @sql_dbname VARCHAR(200);

IF OBJECT_ID('tempdb..#dbs') IS NOT NULL DROP TABLE #dbs;
SELECT
    dbname = [name]
INTO
    #dbs
FROM
    sys.databases
WHERE
        source_database_id IS NULL -- not a database snapshot
    AND is_read_only = 0
    AND [name] NOT IN ('master', 'tempdb', 'model', 'msdb', 'SSISDB');

WHILE EXISTS ( SELECT TOP 1
                *
               FROM
                #dbs )
    BEGIN
        SELECT TOP 1
            @sql_dbname = dbname
          , @sql_db = N'use [' + dbname + '];'
        FROM
            #dbs;

        RAISERROR('Fixing users in database %s...', 0, 1, @sql_dbname) WITH NOWAIT;

        IF OBJECT_ID('tempdb..#alterusr') IS NOT NULL DROP TABLE #alterusr;
        SELECT
            name
          , sqltxt = N'' + @sql_db + 'ALTER USER [' + name + '] WITH LOGIN = [' + name + ']'
        INTO
            #alterusr
        FROM
            sys.server_principals
        WHERE
            [type] IN ('U', 'S', 'G')
            AND is_disabled = 0
            AND name NOT IN ('dbo', 'guest', 'sys', 'INFORMATION_SCHEMA', 'sa', 'NT AUTHORITY\SYSTEM', 'NT SERVICE\MSSQLSERVER', 'NT SERVICE\SQLSERVERAGENT');

        WHILE EXISTS ( SELECT TOP 1
                        *
                       FROM
                        #alterusr )
            BEGIN
                SELECT TOP 1
                    @sql_AU = sqltxt
                  , @sql_name = name
                FROM
                    #alterusr;

                BEGIN TRY
                    EXEC sys.sp_executesql @sql_AU;
                END TRY
                BEGIN CATCH
                    IF ERROR_NUMBER() <> 15151 -- ignore the error "cannot alter the user <foo> because it does not exist"
                        THROW; -- any other error, we should know about
                END CATCH;

                DELETE FROM
                    #alterusr
                WHERE
                    name = @sql_name;
            END;
        DROP TABLE #alterusr;

        DELETE FROM
            #dbs
        WHERE
            dbname = @sql_dbname;
    END;

RAISERROR('Done.', 0, 1) WITH NOWAIT;
DROP TABLE #dbs;
