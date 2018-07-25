USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_DatabaseFileSizes') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_DatabaseFileSizes AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_DatabaseFileSizes
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.DatabaseFileSizes
	WHERE CollectedTime < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
