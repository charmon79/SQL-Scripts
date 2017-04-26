DECLARE @schemaName sysname = 'dbo'
DECLARE @tableName sysname = 'TableName'


SELECT
    t.name AS TableName
,   c.name AS ColumnName
,   refs.*
FROM
    sys.tables AS t
    INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    INNER JOIN sys.columns AS c ON c.object_id = t.object_id
    OUTER APPLY (
        SELECT DISTINCT
            1 AS test
        FROM
            /* objects referencing the table */
            sys.dm_sql_referencing_entities(CONCAT(s.name,'.',t.name),'OBJECT') AS dsre
            CROSS APPLY (
                /* of those objects, find the ones mentioning the column */
                SELECT  *
                FROM    sys.sql_modules AS sm
                WHERE   sm.object_id = dsre.referencing_id
                    AND sm.definition LIKE '%'+c.name+'%'
            ) colref
    ) AS refs
WHERE
        s.name = @schemaName
    AND t.name = @tableName
    AND refs.test IS NULL
ORDER BY 
        t.name
    ,   c.name
;

