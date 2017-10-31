DECLARE @spid INT
    ,   @sql NVARCHAR(max)

WHILE EXISTS (
SELECT blocking_session_id, *
FROM sys.dm_exec_requests AS der
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
WHERE der.blocking_session_id IS NOT NULL
AND der.session_id = 268
AND der.blocking_session_id > 0
--AND der.sql_handle = 0x0300210099DC6171989AF00060A7000001000000000000000000000000000000000000000000000000000000 -- find the plan handle first
)
BEGIN
    SELECT TOP 1 @spid = blocking_session_id
    FROM sys.dm_exec_requests AS der
    CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
    WHERE der.blocking_session_id IS NOT NULL
    AND der.session_id = 268
    --AND der.sql_handle = 0x0300210099DC6171989AF00060A7000001000000000000000000000000000000000000000000000000000000
    AND der.blocking_session_id > 0

    SET @sql = 'KILL ' + CAST(@spid AS VARCHAR(10))
    EXEC (@sql)
END

alter index [IX_UserTableDetail_TableID, PrimaryKeyName] on dbo.UserTableDetail rebuild with (online = on)
GO
alter index [ixUsertabledetailSearchResult] on dbo.UserTableDetail rebuild with (online = on)
GO
alter index [ix_UsertableDetail_Id] on dbo.UserTableDetail rebuild with (online = on)
GO
alter index [IX_UserTableDetail_StatusCode] on dbo.UserTableDetail rebuild with (online = on)
GO
alter index [IX_UserTableDetail_TableID_UserTableDetailStatusCode] on dbo.UserTableDetail rebuild with (online = on)
GO
alter index [IX_UserTableDetail_TableID_IsChecked_HasLoggedHit_PrimaryKeyName] on dbo.UserTableDetail rebuild with (online = on)
GO
alter index [IX_UserTableDetail_TableID_PrimaryKeyID_PrimaryKeyName] on dbo.UserTableDetail rebuild with (online = on)
GO


SELECT *
FROM sys.dm_exec_requests AS der
CROSS APPLY sys.dm_exec_sql_text(der.sql_handle) AS dest
WHERE der.blocking_session_id IS NOT NULL
AND der.session_id = 420