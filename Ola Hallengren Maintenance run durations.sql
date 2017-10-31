
SELECT
    StartDate = CAST(cl.StartTime AS DATE)
,   Duration = DATEDIFF(MINUTE, MIN(cl.StartTime), MAX(cl.EndTime))
FROM dbo.CommandLog AS cl
WHERE cl.CommandType IN ('ALTER_INDEX')
GROUP BY CAST(cl.StartTime AS DATE)
ORDER BY StartDate desc