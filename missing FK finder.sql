USE XDB;

SELECT  o.name AS [Table]
    ,   c.name AS [possible FK column]
FROM    sys.columns AS c
        INNER JOIN sys.tables AS o ON o.object_id = c.object_id
WHERE   1=1
    /* Columns which look like they should be FK to another TABLE */
    AND c.name LIKE '%Id'
    AND o.name <> LEFT(c.name, LEN(c.name) - 2) /* doesn't look like column named [ThingId] in table named [Thing], which should be a PK */
    AND LEFT(c.name, 3) <> 'Old'
    /* Which aren't already part of an FK constraint */
    AND NOT EXISTS (
        SELECT  1
        FROM    sys.foreign_key_columns AS fkc
        WHERE   fkc.parent_object_id = c.object_id
            AND fkc.parent_column_id = c.column_id
    )
    /* And aren't part of the PK on the table they look like they'd be referencing 
       (in case column name is PK of a table but is either part of composite key, or just not following naming convention) */
    AND NOT EXISTS (
        SELECT  o2.name
            ,   kc.name
            ,   i.index_id
            ,   c2.name
        FROM sys.key_constraints AS kc
        INNER JOIN sys.objects AS o2 ON o2.object_id = kc.parent_object_id
        INNER JOIN sys.indexes AS i ON i.object_id = kc.parent_object_id AND i.index_id = kc.unique_index_id
        INNER JOIN sys.index_columns AS ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
        INNER JOIN sys.columns AS c2 ON c2.object_id = ic.object_id AND c2.column_id = ic.column_id
        WHERE c2.object_id = o.object_id AND c2.column_id = c.column_id
    )
;

