DECLARE @login sysname = 'job_runner'
DECLARE @spid int;
DECLARE @sql NVARCHAR(MAX);

WHILE EXISTS (SELECT TOP 1 session_id FROM sys.dm_exec_sessions WHERE login_name = @login)
BEGIN    
    SET @spid = (SELECT TOP 1 session_id FROM sys.dm_exec_sessions WHERE login_name = @login);
    SET @sql = 'KILL '+CAST(@spid AS varchar(10));
    EXEC(@sql);
    RAISERROR('Killed session_id: %i', 0, 1, @spid) WITH NOWAIT;
END
