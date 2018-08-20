USE DBAdmin;
GO

SELECT
	*
FROM
	dbo.WaitStats
WHERE
	PeriodStart >= DATEADD(hour, -12, GETDATE())
ORDER BY
	PeriodStart DESC
,	Percentage DESC
;