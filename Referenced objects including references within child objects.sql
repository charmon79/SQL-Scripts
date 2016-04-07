USE atlas;

WITH cte AS (
    SELECT sed.*
    FROM sys.sql_expression_dependencies AS sed
    INNER JOIN sys.objects AS o ON o.[object_id] = sed.referencing_id
    WHERE o.name IN 
    (
        SELECT name
        FROM sys.objects
        WHERE name LIKE 'sproc_csm_getxdbjsonbatch'
    )

    UNION ALL
    SELECT sed.*
    FROM sys.sql_expression_dependencies AS sed
    INNER JOIN cte ON cte.referenced_id = sed.referencing_id
)
SELECT DISTINCT
    --    OBJECT_NAME(cte.referencing_id) AS referencing_object_name
    --,   
        cte.referenced_database_name
    ,   cte.referenced_schema_name
    ,   cte.referenced_entity_name
    ,   cte.referenced_database_name + '.' + cte.referenced_schema_name + '.' + cte.referenced_entity_name AS FQObjectName
    --,   OBJECT_NAME(cte.referencing_id)
    ,   'SELECT '''
        + cte.referenced_database_name + '.' + cte.referenced_schema_name + '.' + cte.referenced_entity_name
        +''' AS ObjectName, CASE WHEN EXISTS (SELECT * FROM ' + cte.referenced_database_name  + '.sys.objects where parent_object_id = object_id('''
        + cte.referenced_database_name + '.' + cte.referenced_schema_name + '.' + cte.referenced_entity_name
        + ''') AND type = ''PK'') THEN 1 ELSE 0 END AS HasPK' AS SQL_CheckForPKs
FROM cte
WHERE DB_ID(cte.referenced_database_name) IS NOT NULL
ORDER BY 
    cte.referenced_database_name
  , cte.referenced_entity_name
  --, referencing_object_name