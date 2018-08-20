DECLARE @Version NUMERIC(18,10);
SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

-- Do nothing if version is 2008 or earlier
IF @Version < 10.50
SET NOEXEC ON;
GO

exec sp_configure 'show advanced options', 1;
go
reconfigure;
go
exec sp_configure 'backup compression default', 1;
go
reconfigure;
go
