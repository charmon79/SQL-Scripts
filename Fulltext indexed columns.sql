SELECT  o.name AS TableName
    ,   c.name AS ColumnName
    ,   fi.fulltext_catalog_id
    ,   fi.change_tracking_state_desc
    ,   fi.has_crawl_completed
    ,   fi.crawl_type_desc
    ,   fi.crawl_start_date
    ,   fi.crawl_end_date
FROM    sys.fulltext_indexes AS fi
        INNER JOIN sys.fulltext_index_columns AS fic ON fic.object_id = fi.object_id
        INNER JOIN sys.objects AS o ON o.object_id = fi.object_id
        INNER JOIN sys.columns AS c ON c.object_id = fi.object_id AND c.column_id = fic.column_id
WHERE   1=1
    --AND o.name = 'Company'
    --AND fi.crawl_type = 'F'
;