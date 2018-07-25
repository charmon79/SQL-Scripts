USE DBAdmin;
GO

IF OBJECT_ID('dbo.Purge_WaitStats') IS NULL
	EXEC('CREATE PROCEDURE dbo.Purge_WaitStats AS RETURN');
GO

ALTER PROCEDURE dbo.Purge_WaitStats
	@RetentionPeriodDays int
AS

SET NOCOUNT ON;

WHILE 1=1
BEGIN
	DELETE TOP (1000)
	FROM dbo.WaitStats
	WHERE PeriodEnd < DATEADD(day, -@RetentionPeriodDays, GETDATE());

	IF @@ROWCOUNT = 0 BREAK;
END;

GO
