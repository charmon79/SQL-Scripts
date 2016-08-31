WITH    ThingsReferencingTable AS (
    SELECT  sed.referencing_id
          , o1.name AS referencing_name
          , sed.referencing_minor_id
          , c1.name AS referencing_minor_name
          , sed.referencing_class
          , sed.referencing_class_desc
          , sed.is_schema_bound_reference
          , sed.referenced_class
          , sed.referenced_class_desc
          , sed.referenced_server_name
          , sed.referenced_database_name
          , sed.referenced_schema_name
          , sed.referenced_entity_name
          , sed.referenced_id
          , o2.name AS referenced_name
          , sed.referenced_minor_id
          , c2.name AS referenced_minor_name
          , sed.is_caller_dependent
          , sed.is_ambiguous
    FROM    sys.sql_expression_dependencies AS sed
            JOIN sys.objects AS o1 ON o1.object_id = sed.referencing_id
            LEFT JOIN sys.columns AS c1 ON c1.column_id = sed.referencing_minor_id
            LEFT JOIN sys.objects AS o2 ON o2.object_id = sed.referenced_id
            LEFT JOIN sys.columns AS c2 ON c2.column_id = sed.referenced_minor_id
    WHERE   o2.name = 'Property_Extension' -- name of table we're looking for references to
)
SELECT *
INTO #referencing
FROM ThingsReferencingTable

SELECT o.name AS ObjectName, o.type AS ObjectType, o.type_desc AS ObjectTypeDesc, sm.[definition]
FROM sys.sql_modules AS sm
INNER JOIN sys.objects AS o ON o.object_id = sm.object_id
INNER JOIN #referencing AS t ON t.referencing_id = o.object_id
WHERE sm.[definition] LIKE '%NumberUnits2%'
ORDER BY o.type, o.name;

SELECT * FROM #referencing AS r