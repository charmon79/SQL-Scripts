USE XDB;
GO

SELECT
    s.name AS [schema]
,   o.name AS [object]
,   o.type_desc AS object_type
,   re.referenced_schema_name AS referenced_schema
,   re.referenced_entity_name AS referenced_object
,   re.referenced_minor_name AS referenced_column
,   re.referenced_class_desc
,   re.is_caller_dependent
,   re.is_ambiguous
,   re.is_selected
,   re.is_updated
,   re.is_select_all
,   re.is_all_columns_found
FROM sys.schemas AS s
INNER JOIN sys.objects AS o ON o.schema_id = s.schema_id
CROSS APPLY sys.dm_sql_referenced_entities((QUOTENAME(s.name) + '.' + QUOTENAME(o.name)), 'OBJECT') AS re
WHERE re.referenced_entity_name = 'Address'
AND re.referenced_minor_name = 'ZipCode'
