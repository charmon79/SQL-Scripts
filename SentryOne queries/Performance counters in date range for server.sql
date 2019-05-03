


declare @start int = ( select dbo.fnConvertDateTimeToTimestamp('2018-12-18 13:00') )-- 2018-12-18 07:00 CST
    ,   @end   int = ( select dbo.fnConvertDateTimeToTimestamp('2018-12-18 15:00') )-- 2018-12-18 09:00 CST

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
    TOP 100
    d.HostName
,   c.ObjectName
,   p.CategoryName
,   p.CounterName
--,   p.StartTimestamp
,   DATEADD( hour, -6, dbo.fnConvertTimestampToDateTime(p.StartTimeStamp) ) AS StartTime -- stored in UTC, was CST at this point
--,   p.Timestamp
,   DATEADD( hour, -6, dbo.fnConvertTimestampToDateTime(p.TimeStamp) ) AS EndTime
,   p.InstanceName
,   p.Value
,   p.SampleCount
,   p.MinVal
,   p.MaxVal
,   p.StdDevVal
FROM
    dbo.Device AS d
    JOIN dbo.EventSourceConnection AS c ON c.DeviceID = d.ID
    JOIN ctePerfCounters p ON p.DeviceID = d.ID AND p.EventSourceConnectionID = c.ID
WHERE 1=1
    and c.ServerName = 'SQL01.lab.local'
    --and CategoryName = 'PhysicalDisk'
    --and (CounterName = '% Processor Time' and CategoryName = 'Processor')
    --AND p.CounterName IN (
    --    'User Connections'
    --,   'Batch Requests/sec'
    --)
    and p.CounterName = 'Avg. Disk sec/Read'
;

select * from  dbo.PerformanceAnalysisCounterCategory
where CategoryName


select pacc.CategoryResourceName, pacc.CategoryName, pac.*
from dbo.PerformanceAnalysisCounter AS pac
        JOIN dbo.PerformanceAnalysisCounterCategory AS pacc ON pacc.ID = pac.PerformanceAnalysisCounterCategoryID
where
    1=1
    and pacc.CategoryName LIKE '%disk%' 
    --and (pac.countername like '%processor%' or pac.countername like '%cpu%')
    and pac.CounterName like '%compil%'