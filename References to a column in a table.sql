USE XcelWeb_Prod;
go

DECLARE @tableName NVARCHAR(257) = 'dbo.city_alias'
    --,   @columnName NVARCHAR(128) = 'CSRAgentID'

/* first, find all objects referencing a the table */
SELECT  DISTINCT
        o.type_desc AS referencing_type
    ,   dsre.*
FROM    sys.dm_sql_referencing_entities(@tableName,'OBJECT') AS dsre
        JOIN sys.objects AS o ON o.object_id = dsre.referencing_id
        CROSS APPLY (
            /* of those objects, find the ones mentioning the column */
            SELECT  *
            FROM    sys.sql_modules AS sm
            WHERE   sm.object_id = dsre.referencing_id
                --AND sm.definition LIKE '%'+@columnName+'%'
        ) colref
WHERE   dsre.referencing_entity_name NOT LIKE 'syncobj_%' -- ignore replication SPs


