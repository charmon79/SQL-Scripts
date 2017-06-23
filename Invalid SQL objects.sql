use XcelWeb_Prod;
GO

/***********************************************************************************************************
    Find SQL modules (procedures, functions, triggers, views) in the database which are invalid
    (e.g., they have broken references to objects which no longer exist)


    !!!WARNING!!! - Might be getting false positives with this. Need to research further before making
                    decisions based on the output from this script.
***********************************************************************************************************/

IF object_id('tempdb..#output') IS NOT NULL DROP TABLE #output;
CREATE TABLE #output
    (
        SchemaName sysname NOT NULL
    ,   ObjectName sysname NOT NULL
    ,   ObjectType VARCHAR(20) NOT NULL
    ,   ErrorText  NVARCHAR(MAX)
    );

DECLARE
    @schemaName   sysname
,   @objectName   sysname
,   @objectType   VARCHAR(20)
,   @fqObjectName NVARCHAR(500);

DECLARE cur_Objects CURSOR LOCAL FAST_FORWARD FOR
    SELECT
        s.name AS SchemaName
    ,   o.name AS ObjectName
    ,   o.type_desc AS ObjectType
    ,   s.name + '.' + o.name AS fqObjectName
    FROM
        sys.sql_modules AS sm
        JOIN sys.objects AS o
            ON o.object_id = sm.object_id
        JOIN sys.schemas AS s
            ON s.schema_id = o.schema_id;

OPEN cur_Objects;

FETCH NEXT FROM cur_Objects
INTO @schemaName, @objectName, @objectType, @fqObjectName;

WHILE @@FETCH_STATUS = 0
BEGIN
    BEGIN TRY
        EXEC sys.sp_refreshsqlmodule @name = @fqObjectName;        
    END TRY
    BEGIN CATCH
        IF ERROR_NUMBER() NOT IN (
            3729 -- Cannot DROP|ALTER <object> because it is being referenced
        )
        INSERT #output
            (
                SchemaName
            ,   ObjectName
            ,   ObjectType
            ,   ErrorText
            )
        VALUES (
                    @schemaName
                ,   @objectName
                ,   @objectType
                ,   ERROR_MESSAGE()
               );
    END CATCH

    FETCH NEXT FROM cur_Objects
    INTO @schemaName, @objectName, @objectType, @fqObjectName;
END;

CLOSE cur_Objects;
DEALLOCATE cur_Objects;

SELECT * FROM #output AS o
ORDER BY o.ObjectType, o.SchemaName, o.ObjectName;

