/*
select dateadd(hour, 6, '2018-12-18 07:00')
select dateadd(hour, 6, '2018-12-18 09:00')
*/

declare @start int = ( select dbo.fnConvertDateTimeToTimestamp('2018-12-18 13:00') )
    ,   @end   int = ( select dbo.fnConvertDateTimeToTimestamp('2018-12-18 15:00') )

;WITH ctePerfCounters AS (
SELECT
    1 as foo
,   pacc.CategoryResourceName
,   pacc.CategoryName
,   pac.CounterResourceName
,   pac.CounterName
--,   
,   dat.*
FROM
    dbo.PerformanceAnalysisDataRollup2 AS dat
    JOIN dbo.PerformanceAnalysisCounter AS pac
        JOIN dbo.PerformanceAnalysisCounterCategory AS pacc ON pacc.ID = pac.PerformanceAnalysisCounterCategoryID
    ON pac.ID = dat.PerformanceAnalysisCounterID

WHERE
    dat.Timestamp BETWEEN @start AND @end
)
SELECT
    --TOP 100
    d.HostName
,   c.ObjectName
--,   p.CategoryName
--,   p.CounterName
--,   p.StartTimestamp
,   DATEADD( hour, -6, dbo.fnConvertTimestampToDateTime(p.StartTimeStamp) ) AS StartTime -- stored in UTC, was CST at this point
--,   p.Timestamp
,   DATEADD( hour, -6, dbo.fnConvertTimestampToDateTime(p.TimeStamp) ) AS EndTime
,   MAX(CASE WHEN CounterName = 'User Connections' THEN SampleCount ELSE 0 END) AS [User Connections:SampleCount]
,   MAX(CASE WHEN CounterName = 'User Connections' THEN Value ELSE 0 END) AS [User Connections:Value]
--,   MAX(CASE WHEN CounterName = 'User Connections' THEN MinVal ELSE 0 END) AS [User Connections:MinVal]
--,   MAX(CASE WHEN CounterName = 'User Connections' THEN MaxVal ELSE 0 END) AS [User Connections:MaxVal]
,   MAX(CASE WHEN CounterName = 'User Connections' THEN StdDevVal ELSE 0 END) AS [User Connections:StdDevVal]
,   MAX(CASE WHEN CounterName = 'Batch Requests/sec' THEN SampleCount ELSE 0 END) AS [Batch Requests/sec:SampleCount]
,   MAX(CASE WHEN CounterName = 'Batch Requests/sec' THEN Value ELSE 0 END) AS [Batch Requests/sec:Value]
--,   MAX(CASE WHEN CounterName = 'Batch Requests/sec' THEN MinVal ELSE 0 END) AS [Batch Requests/sec:MinVal]
--,   MAX(CASE WHEN CounterName = 'Batch Requests/sec' THEN MaxVal ELSE 0 END) AS [Batch Requests/sec:MaxVal]
,   MAX(CASE WHEN CounterName = 'Batch Requests/sec' THEN StdDevVal ELSE 0 END) AS [Batch Requests/sec:StdDevVal]
,   MAX(CASE WHEN p.CounterName = 'SQL Compilations/sec' THEN p.SampleCount ELSE 0 END) AS [SQL Compilations/sec:p.SampleCount]
,   MAX(CASE WHEN p.CounterName = 'SQL Compilations/sec' THEN p.Value ELSE 0 END) AS [SQL Compilations/sec:p.Value]
--,   MAX(CASE WHEN p.CounterName = 'SQL Compilations/sec' THEN p.MinVal ELSE 0 END) AS [SQL Compilations/sec:p.MinVal]
--,   MAX(CASE WHEN p.CounterName = 'SQL Compilations/sec' THEN p.MaxVal ELSE 0 END) AS [SQL Compilations/sec:p.MaxVal]
,   MAX(CASE WHEN p.CounterName = 'SQL Compilations/sec' THEN p.StdDevVal ELSE 0 END) AS [SQL Compilations/sec:p.StdDevVal]
,   MAX(CASE WHEN p.CounterName = 'SQL Re-Compilations/sec' THEN p.SampleCount ELSE 0 END) AS [SQL Re-Compilations/sec:p.SampleCount]
,   MAX(CASE WHEN p.CounterName = 'SQL Re-Compilations/sec' THEN p.Value ELSE 0 END) AS [SQL Re-Compilations/sec:p.Value]
--,   MAX(CASE WHEN p.CounterName = 'SQL Re-Compilations/sec' THEN p.MinVal ELSE 0 END) AS [SQL Re-Compilations/sec:p.MinVal]
--,   MAX(CASE WHEN p.CounterName = 'SQL Re-Compilations/sec' THEN p.MaxVal ELSE 0 END) AS [SQL Re-Compilations/sec:p.MaxVal]
,   MAX(CASE WHEN p.CounterName = 'SQL Re-Compilations/sec' THEN p.StdDevVal ELSE 0 END) AS [SQL Re-Compilations/sec:p.StdDevVal]
FROM
    dbo.Device AS d
    JOIN dbo.EventSourceConnection AS c ON c.DeviceID = d.ID
    JOIN ctePerfCounters p ON p.DeviceID = d.ID AND p.EventSourceConnectionID = c.ID
WHERE 1=1
    and c.ServerName = 'SQL01.lab.local'
    AND p.CounterName IN (
        'User Connections'
    ,   'Batch Requests/sec'
    ,   'SQL Compilations/sec'
    ,   'SQL Re-Compilations/sec'
    )
GROUP BY
    d.HostName
,   c.ObjectName
--,   p.StartTimestamp
,   DATEADD( hour, -6, dbo.fnConvertTimestampToDateTime(p.StartTimeStamp) ) 
--,   p.Timestamp
,   DATEADD( hour, -6, dbo.fnConvertTimestampToDateTime(p.TimeStamp) )
;