USE DBAdmin;
GO

/*
    Analyzes the collected WaitStats data for a broad time period,
    showing the overall top waits for the time period,
    as well as the worst monitored sub-periods for each
    wait type to help with identifying spikes in certain waits.
*/

DECLARE @PeriodStart DATETIME
	,	@PeriodEnd DATETIME;

SET @PeriodStart = DATEADD(hour, -24, GETDATE());
SET @PeriodEnd = GETDATE();

WITH WaitStatsForPeriod AS (
    SELECT
        *
    FROM
        dbo.WaitStats
    WHERE 
        PeriodStart >= @PeriodStart
        AND PeriodEnd <= @PeriodEnd
)
,   OverallPercentages AS (
    SELECT
        w.WaitType
    ,   MIN(PeriodStart) AS PeriodStart
    ,   MAX(PeriodEnd) AS PeriodEnd
    ,   SUM(w.Wait_S) AS TotalWait_S
    ,   100.0 * SUM(w.Wait_S) / t.Wait_S AS PercentOfTotal
    FROM
        WaitStatsForPeriod AS w
        CROSS JOIN (
            SELECT SUM(Wait_S) AS Wait_S
            FROM WaitStatsForPeriod
        ) AS t
    GROUP BY
        w.WaitType
    ,   t.Wait_S
    )
,   WorstPeriodsPerWait AS (
    SELECT
        WaitType
    ,   PeriodStart
    ,   PeriodEnd
    ,   AvgWait_S
    ,   ROW_NUMBER() OVER (PARTITION BY WaitType ORDER BY Wait_S DESC) AS PeriodRank
    FROM
        WaitStatsForPeriod
)
SELECT
    op.PeriodStart
,   op.PeriodEnd
,   op.WaitType
,   op.TotalWait_S
,   op.PercentOfTotal
,   wp.PeriodStart AS WaitTypeWorstPeriodStart
,   wp.PeriodEnd AS WaitTypeWorstPeriodEnd
,   wp.AvgWait_S AS WorstPeriod_AvgWait_S
FROM
    OverallPercentages AS op
    JOIN WorstPeriodsPerWait AS wp
        ON wp.WaitType = op.WaitType
        AND wp.PeriodRank = 1
ORDER BY
    op.PercentOfTotal DESC
;
