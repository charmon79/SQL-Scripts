USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_WhoIsActive') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_WhoIsActive AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_WhoIsActive
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.WhoIsActiveStats
	WHERE collection_time < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
