USE tempdb;

SELECT GETDATE() AS runtime, 
       SUM(user_object_reserved_page_count) * 8 AS usr_obj_kb, 
       SUM(internal_object_reserved_page_count) * 8 AS internal_obj_kb, 
       SUM(version_store_reserved_page_count) * 8 AS version_store_kb, 
       SUM(unallocated_extent_page_count) * 8 AS freespace_kb, 
       SUM(mixed_extent_page_count) * 8 AS mixedextent_kb
FROM sys.dm_db_file_space_usage;