DECLARE @spid INT
    ,   @sql NVARCHAR(max)

WHILE EXISTS (
SELECT *
FROM sys.dm_exec_requests AS der
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
WHERE der.blocking_session_id IS NOT NULL
AND der.session_id > 50
--AND der.sql_handle = 0x0300070099DC6171989AF00060A7000001000000000000000000000000000000000000000000000000000000 -- find the plan handle first
)
BEGIN
    SELECT TOP 1 @spid = session_id
    FROM sys.dm_exec_requests AS der
    CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
    WHERE der.blocking_session_id IS NOT NULL
    AND der.session_id > 50
    --AND der.sql_handle = 0x0300070099DC6171989AF00060A7000001000000000000000000000000000000000000000000000000000000

    SET @sql = 'KILL ' + CAST(@spid AS VARCHAR(10))
    EXEC (@sql)
END
--ALTER INDEX ALL on dbo.UserTableDetail REBUILD WITH (ONLINE = ON)