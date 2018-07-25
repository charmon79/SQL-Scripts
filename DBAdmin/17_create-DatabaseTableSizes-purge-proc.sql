USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_DatabaseTableSizes') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_DatabaseTableSizes AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_DatabaseTableSizes
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.DatabaseTableSizes
	WHERE CollectedTime < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
