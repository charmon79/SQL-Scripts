/***********************************************************************************************************
    This script will demonstrate how to use sp_executesql with a parameterized query to ensure
    safety against SQL injection within a stored procedure.

    First, let's create a couple of temporary stored procedures.
***********************************************************************************************************/

    -- We're going to use the EXEC() method in this procedure.
    IF object_id('tempdb..#DynamicSQLDemo_UNSAFE') IS NOT NULL DROP PROCEDURE #DynamicSQLDemo_UNSAFE;
    GO
    CREATE PROCEDURE #DynamicSQLDemo_UNSAFE
    (       @ObjectName NVARCHAR(128)
        ,   @SchemaName NVARCHAR(128)
        ,   @ObjectType CHAR(2)
    )
    AS
    BEGIN
        DECLARE @sql NVARCHAR(MAX);

        SET @sql = '';

        SET @sql += '
            SELECT o.*
            FROM sys.objects AS o
            INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
            WHERE 1=1
        ';

        IF @ObjectName IS NOT NULL
            SET @sql += ' AND o.name = ''' + @ObjectName + ''''
        ;

        IF @SchemaName IS NOT NULL
            SET @sql += ' AND s.name = ''' + @SchemaName + ''''
        ;

        IF @ObjectType IS NOT NULL
            SET @sql += ' AND o.type = ''' + @ObjectType + ''''
        ;

        PRINT @sql;
        EXEC (@sql);
    END;
    GO

    -- We're going to use the parameterized sp_executesql method in this procedure.
    IF object_id('tempdb..#DynamicSQLDemo_SAFE') IS NOT NULL DROP PROCEDURE #DynamicSQLDemo_SAFE;
    GO
    CREATE PROCEDURE #DynamicSQLDemo_SAFE
    (       @ObjectName NVARCHAR(128)
        ,   @SchemaName NVARCHAR(128)
        ,   @ObjectType CHAR(2)
    )
    AS
    BEGIN
        DECLARE @sql NVARCHAR(MAX);
        SET @sql = '';

        SET @sql += '
            SELECT o.*
            FROM sys.objects AS o
            INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
            WHERE 1=1
        ';

        IF @ObjectName IS NOT NULL
            SET @sql += ' AND o.name = @ObjectName '
        ;

        IF @SchemaName IS NOT NULL
            SET @sql += ' AND s.name = @SchemaName '
        ;

        IF @ObjectType IS NOT NULL
            SET @sql += ' AND o.type = @ObjectType '
        ;

        PRINT @sql;
        EXEC sys.sp_executesql
            @sql -- the parameterized query string
        ,   N'@ObjectName NVARCHAR(128), @SchemaName NVARCHAR(128), @ObjectType CHAR(2)' -- declare the parameters that exist in @sql
        ,   @ObjectName = @ObjectName -- pass our outer variables to the inner parameters
        ,   @SchemaName = @SchemaName
        ,   @ObjectType = @ObjectType
        ;
    END;
    GO

/***********************************************************************************************************
    Now, let's play with those procedures and see what happens...

    First, let's just run both of them & compare the results.
***********************************************************************************************************/
EXEC dbo.#DynamicSQLDemo_UNSAFE
    @ObjectName = 'sysclones'
,   @SchemaName = NULL
,   @ObjectType = 'S'
;

EXEC dbo.#DynamicSQLDemo_SAFE
    @ObjectName = 'sysclones'
,   @SchemaName = NULL
,   @ObjectType = 'S'
;


/***********************************************************************************************************
    Nifty, they both do the same thing - right?

    But what if we try to do a little SQL injection?
***********************************************************************************************************/
EXEC dbo.#DynamicSQLDemo_UNSAFE
    @ObjectName = '''; SELECT * FROM sys.databases; --' -- tadaa! successful SQL injection!
,   @SchemaName = NULL
,   @ObjectType = 'S'
;

EXEC dbo.#DynamicSQLDemo_SAFE
    @ObjectName = '''; SELECT * FROM sys.databases; --' -- ha! foiled you, you n00b hacker!
,   @SchemaName = NULL
,   @ObjectType = 'S'
;