/* Script ouf FT indexes */
SELECT  s.name AS SchemaName
    ,   t.name AS TableName
    ,   i.name AS UniqueKeyName
    ,   fc.name AS FTCatalogName
    ,   fs.name AS FTStoplistName
    ,   ColumnList = STUFF((    SELECT ',' + QUOTENAME(c.Name) AS [text()]
                                FROM sys.columns AS c
                                        JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id AND fic.column_id = c.column_id
                                WHERE   c.object_id = fi.object_id
                                ORDER BY c.column_id
                                FOR XML PATH('') 
                                ), 1, 1, '' ) 
    ,   CreateSQL = 'CREATE FULLTEXT INDEX ON '+QUOTENAME(s.name)+'.'+QUOTENAME(t.name) + '
            ('
        +   STUFF((    SELECT ',' + QUOTENAME(c.Name) AS [text()]
                       FROM sys.columns AS c
                               JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id AND fic.column_id = c.column_id
                       WHERE   c.object_id = fi.object_id
                       ORDER BY c.column_id
                       FOR XML PATH('') 
                       ), 1, 1, '' ) +')
        KEY INDEX '+QUOTENAME(i.name)+'
        ON '+QUOTENAME(fc.name)+'
        WITH ( STOPLIST = '+QUOTENAME(fs.name)+' , CHANGE_TRACKING = AUTO);
        '
FROM    sys.fulltext_indexes AS fi
        INNER JOIN sys.fulltext_catalogs AS fc ON fc.fulltext_catalog_id = fi.fulltext_catalog_id
        INNER JOIN sys.fulltext_stoplists AS fs ON fs.stoplist_id = fi.stoplist_id
        INNER JOIN sys.tables AS t ON t.object_id = fi.object_id
        INNER JOIN sys.schemas AS s ON s.schema_id = t.schema_id
        INNER JOIN sys.indexes AS i ON i.object_id = fi.object_id AND i.index_id = fi.unique_index_id
;