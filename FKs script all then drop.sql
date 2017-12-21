USE tempdb; -- replace with the intended database name
GO

DECLARE @sql NVARCHAR(MAX);

/*
    Script CREATEs for all FKs to a temporary table within the database
    (we need this to persist so a subsequent script can reference it, hence not using a # temp table).
*/
--DECLARE @sql NVARCHAR(MAX);

IF object_id('dbo.__TEMP__FKCreates') IS NULL
BEGIN
    CREATE TABLE [dbo].[__TEMP__FKCreates] (DDL NVARCHAR(MAX));
    INSERT [dbo].[__TEMP__FKCreates]
    SELECT  'ALTER TABLE ' + QUOTENAME(fos.name)+'.'+QUOTENAME(fo.name) 
    +' WITH NOCHECK ' -- I didn't want to use NOCHECK, but it's too much maintenance work right now to load a referentially correct sample set of data for all tables in the correct order to pass FK checks
                      -- Long term goal is not to have to do this, but it's not strictly necessary for local dev/test environments and it's making maintenance of this whole process a huge PITA as tables change.
    +'ADD CONSTRAINT '+QUOTENAME(fk.name)+' FOREIGN KEY ('+
    STUFF((    SELECT ',' + QUOTENAME(c.Name) AS [text()]
                                        FROM sys.columns AS c
                                             JOIN sys.foreign_key_columns AS fkc ON fkc.parent_object_id = c.object_id AND fkc.parent_column_id = c.column_id
                                        WHERE   fkc.constraint_object_id = fk.object_id
                                        ORDER BY c.column_id
                                        FOR XML PATH('') 
                                        ), 1, 1, '' ) -- Referencing Columns
    +')
    REFERENCES ' + QUOTENAME(pos.name)+'.'+QUOTENAME(po.name) +' ('+
    STUFF((    SELECT ',' + QUOTENAME(c.Name) AS [text()]
                                        FROM sys.columns AS c
                                             JOIN sys.foreign_key_columns AS fkc ON fkc.referenced_object_id = c.object_id AND fkc.referenced_column_id = c.column_id
                                        WHERE   fkc.constraint_object_id = fk.object_id
                                        ORDER BY c.column_id
                                        FOR XML PATH('') 
                                        ), 1, 1, '' ) -- Referenced Columns
    + ')'
    + CASE fk.delete_referential_action
        WHEN 1 THEN ' ON DELETE CASCADE'
        WHEN 2 THEN ' ON DELETE SET NULL'
        WHEN 3 THEN ' ON DELETE SET DEFAULT'
        ELSE ''
      END -- on delete action
    + CASE fk.update_referential_action
        WHEN 1 THEN ' ON UPDATE CASCADE'
        WHEN 2 THEN ' ON UPDATE SET NULL'
        WHEN 3 THEN ' ON UPDATE SET DEFAULT'
        ELSE ''
      END -- on update action
    +';'
    FROM    sys.foreign_keys AS fk
            INNER JOIN sys.objects AS fo ON fo.object_id = fk.parent_object_id
            INNER JOIN sys.schemas AS fos ON fos.schema_id = fo.schema_id
            INNER JOIN sys.objects AS po ON po.object_id = fk.referenced_object_id
            INNER JOIN sys.schemas AS pos ON pos.schema_id = po.schema_id
    WHERE   fo.is_ms_shipped = 0
    ;
END

/*
    Step 4: Script DROPs for all FKs and drop them all.
*/
DECLARE cur_DropFKs CURSOR LOCAL FAST_FORWARD FOR
    SELECT  'ALTER TABLE ' + QUOTENAME(fos.name)+'.'+QUOTENAME(fo.name) +'
    DROP CONSTRAINT '+QUOTENAME(fk.name)+';' AS [sql]
    FROM    sys.foreign_keys AS fk
            INNER JOIN sys.objects AS fo ON fo.object_id = fk.parent_object_id
            INNER JOIN sys.schemas AS fos ON fos.schema_id = fo.schema_id
    WHERE   fo.is_ms_shipped = 0
;
OPEN cur_DropFKs;
FETCH NEXT FROM cur_DropFKs INTO @sql;
WHILE @@FETCH_STATUS = 0 BEGIN
    EXEC (@sql);
    FETCH NEXT FROM cur_DropFKs INTO @sql;
END
CLOSE cur_DropFKs;
DEALLOCATE cur_DropFKs;