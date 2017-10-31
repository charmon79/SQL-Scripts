--USE XcelWeb_Prod_TEST;

--sp_whoisactive

WITH    cteAllocationUnits AS (
    /* in-row data */
    SELECT
        au.allocation_unit_id
    ,   au.type
    ,   au.type_desc
    ,   au.container_id
    ,   au.data_space_id
    ,   (au.total_pages * 8.0) / 1024.0 AS TotalMB
    ,   (au.used_pages * 8.0) / 1024.0 AS UsedMB
    ,   (au.data_pages * 8.0) / 1024.0 AS DataMB
    ,   s.name AS SchemaName
    ,   o.object_id
    ,   o.name AS ObjectName
    ,   o.is_ms_shipped
    ,   i.index_id
    ,   CASE i.index_id WHEN 0 THEN '--HEAP--' ELSE i.name END AS IndexName
    FROM sys.allocation_units AS au
        JOIN sys.partitions AS p ON p.hobt_id = au.container_id
        JOIN sys.objects AS o ON o.object_id = p.object_id
        JOIN sys.indexes AS i ON i.index_id = p.index_id AND i.object_id = p.object_id
        JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE au.type IN (1, 3)

    UNION ALL

    /* LOB data */
    SELECT
        au.allocation_unit_id
    ,   au.type
    ,   au.type_desc
    ,   au.container_id
    ,   au.data_space_id
    ,   (au.total_pages * 8.0) / 1024.0 AS TotalMB
    ,   (au.used_pages * 8.0) / 1024.0 AS UsedMB
    ,   (au.data_pages * 8.0) / 1024.0 AS DataMB
    ,   s.name AS SchemaName
    ,   o.object_id
    ,   o.name AS ObjectName
    ,   o.is_ms_shipped
    ,   i.index_id
    ,   CASE i.index_id WHEN 0 THEN '--HEAP--' ELSE i.name END AS IndexName
    FROM sys.allocation_units AS au
        JOIN sys.partitions AS p ON p.partition_id = au.container_id
        JOIN sys.objects AS o ON o.object_id = p.object_id
        JOIN sys.indexes AS i ON i.index_id = p.index_id AND i.object_id = p.object_id
        JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    WHERE au.type = 2

    UNION ALL

    /* marked for deferred drop */
    SELECT
        au.allocation_unit_id
    ,   au.type
    ,   au.type_desc
    ,   au.container_id
    ,   au.data_space_id
    ,   (au.total_pages * 8.0) / 1024.0 AS TotalMB
    ,   (au.used_pages * 8.0) / 1024.0 AS UsedMB
    ,   (au.data_pages * 8.0) / 1024.0 AS DataMB
    ,   NULL AS SchemaName
    ,   NULL AS object_id
    ,   NULL AS ObjectName
    ,   NULL AS is_ms_shipped
    ,   NULL AS index_id
    ,   NULL AS IndexName
    FROM sys.allocation_units AS au
    WHERE au.container_id = 0
)
--SELECT TOP 100
--    *
--FROM
--    cteAllocationUnits
--ORDER BY
--    cteAllocationUnits.UsedMB DESC
SELECT
    SchemaName
,   ObjectName
,   SUM(TotalMB) AS SizeMB
FROM
    cteAllocationUnits
GROUP BY
    SchemaName
,   ObjectName
ORDER BY
    SizeMB DESC
;