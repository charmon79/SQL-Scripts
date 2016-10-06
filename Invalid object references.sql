

WITH    cteModules AS (
            SELECT  sm.object_id
                ,   s.name AS SchemaName
                ,   o.name AS ObjectName
                ,   s.name + '.' + o.name AS QualifiedName
                ,   o.type_desc AS ObjectType
            FROM    sys.sql_modules AS sm
                    INNER JOIN sys.objects AS o ON o.object_id = sm.object_id
                    INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
        )
    ,   cteReferences AS (
            SELECT  m.*
                ,   dsre.*
            FROM    cteModules AS m
                    CROSS APPLY sys.dm_sql_referenced_entities(m.QualifiedName,'OBJECT') AS dsre
            WHERE   ISNULL(dsre.referenced_database_name,'') NOT IN (
                        'DataStage'
                    )
    )
    ,   cteFinal AS (
            SELECT  *
            FROM    cteReferences AS r
            WHERE   r.referenced_class = 1 -- OBJECT_OR_COLUMN
                AND NOT EXISTS (
                        SELECT  1
                        FROM    sys.objects AS o
                                INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
                        WHERE   o.name = r.referenced_entity_name
                            --AND (r.referenced_schema_name IS NULL OR s.name = r.referenced_schema_name)
                    )
                AND r.referenced_entity_name NOT IN ('Company_User')
            UNION ALL
            SELECT  *
            FROM    cteReferences AS r
            WHERE   r.referenced_class = 6 -- TYPE
                AND NOT EXISTS (
                        SELECT  1
                        FROM    sys.types AS o
                                INNER JOIN sys.schemas AS s ON s.schema_id = o.schema_id
                        WHERE   o.name = r.referenced_entity_name
                            AND (r.referenced_schema_name IS NULL OR s.name = r.referenced_schema_name)
                    )
        )
SELECT  CONCAT('***', COUNT(DISTINCT object_id), ' total objects ***')
      , '' AS SchemaName
      , '' AS ObjectName
      , '' AS referenced_class_desc
      , '' AS referenced_server_name
      , '' AS referenced_database_name
      , '' AS referenced_schema_name
      , '' AS referenced_entity_name
      , '' AS referenced_minor_name
      , '' AS is_all_columns_found
      , '' AS is_select_all
      , '' AS is_updated
      , '' AS is_selected
      , '' AS is_ambiguous
      , '' AS is_caller_dependent
FROM    cteFinal
UNION ALL
SELECT  ObjectType
      , SchemaName
      , ObjectName
      , referenced_class_desc
      , referenced_server_name
      , referenced_database_name
      , referenced_schema_name
      , referenced_entity_name
      , referenced_minor_name
      , is_all_columns_found
      , is_select_all
      , is_updated
      , is_selected
      , is_ambiguous
      , is_caller_dependent
FROM    cteFinal
ORDER BY
        ObjectName
    ,   referenced_database_name
    ,   referenced_schema_name
    ,   referenced_entity_name
;