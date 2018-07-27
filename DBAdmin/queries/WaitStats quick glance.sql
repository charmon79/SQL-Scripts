USE DBAdmin;
GO

SELECT
	*
FROM
	dbo.WaitStats
WHERE
	PeriodStart >= DATEADD(hour, -6, GETDATE())
ORDER BY
	PeriodStart DESC
,	Percentage DESC
;