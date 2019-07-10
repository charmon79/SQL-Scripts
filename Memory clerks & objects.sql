--Memory objects using memory from a Memory Clerk
SELECT --top 10
    mc.type AS clerk_type
,   mc.name AS clerk_name
--,   mc.pages_kb AS clerk_kb
,   CAST((SUM(DISTINCT mc.pages_kb) / 1024.0) AS DECIMAL(15,2)) AS clerk_mb
,   mo.type AS object_type
,   mo.name AS object_name
--,   mo.page_size_in_bytes AS object_bytes
,   CAST((SUM(mo.page_size_in_bytes) / 1048576.0) AS DECIMAL(15,2)) AS object_mb
--,   mo.max_pages_in_bytes AS object_max_bytes
,   CAST((SUM(mo.max_pages_in_bytes) / 1048576.0) AS DECIMAL(15,2)) AS object_max_mb
FROM 
     sys.dm_os_memory_clerks mc
     LEFT JOIN sys.dm_os_memory_objects mo
        ON mc.page_allocator_address = mo.page_allocator_address
GROUP BY
    mc.type
,   mc.name
,   mo.type
,   mo.name
ORDER BY 
--         mc.type
--       , mo.type
    SUM(DISTINCT mc.pages_kb) DESC
,   SUM(mo.page_size_in_bytes) DESC
   --SUM(mo.max_pages_in_bytes) DESC
;
GO