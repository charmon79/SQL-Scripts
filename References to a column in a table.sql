DECLARE @tableName NVARCHAR(257) = 'dbo.TableName'
    ,   @columnName NVARCHAR(128) = 'ColumnName'

/* first, find all objects referencing a the table */
SELECT  DISTINCT
        dsre.*
FROM    sys.dm_sql_referencing_entities(@tableName,'OBJECT') AS dsre
CROSS APPLY (
    /* of those objects, find the ones mentioning the column */
    SELECT  *
    FROM    sys.sql_modules AS sm
    WHERE   sm.object_id = dsre.referencing_id
        AND sm.definition LIKE '%'+@columnName+'%'
) colref


