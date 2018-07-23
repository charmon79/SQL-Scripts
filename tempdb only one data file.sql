SELECT COUNT(1)
FROM tempdb.sys.database_files
WHERE type = 0
HAVING COUNT(1) = 1