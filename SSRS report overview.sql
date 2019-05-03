USE ReportServer;
SELECT 
       [Path] = SUBSTRING(c.[Path], 1, LEN(c.[Path])-(CHARINDEX('/', REVERSE(c.[Path]))-1))
     , [Report Name] = c.Name
     , [Hidden] = CASE
                      WHEN c.[Hidden] = 1
                      THEN 'Yes'
                      ELSE 'No'
                  END
     , [Last Executed] = CONVERT(VARCHAR, ISNULL(el.TimeStart, S.LastRunTime), 120)
     , [Execution Result] = el.Status
     , [Subscriptions] = s.NumSubscriptions
     , [Shared Data Sources] = ds.NumSharedDS
     , [Custom Data Sources] = ds.NumCustomDS
FROM 
     dbo.[Catalog] c
     OUTER APPLY
    (
        SELECT TOP 1
            TimeStart
        ,   Status
        FROM 
                dbo.ExecutionLog3
        WHERE ItemPath = c.Path
        ORDER BY TimeStart DESC
    ) AS el
    OUTER APPLY (
        SELECT
            NumSharedDS = SUM(CASE WHEN Link IS NOT NULL THEN 1 ELSE 0 END) 
        ,   NumCustomDS = SUM(CASE WHEN Link IS NULL THEN 1 ELSE 0 END) 
        FROM
            dbo.DataSource
        WHERE
            ItemID = c.ItemID
    ) AS ds
    OUTER APPLY (
        SELECT
            COUNT(1) AS NumSubscriptions
        ,   MAX(S.LastRunTime) LastRunTime
        FROM
            dbo.[Subscriptions] S
            LEFT JOIN dbo.ReportSchedule R
                ON S.SubscriptionID = R.SubscriptionID
             LEFT JOIN msdb.dbo.sysjobs J
                ON CONVERT(NVARCHAR(128), R.ScheduleID) = J.name
             LEFT JOIN msdb.dbo.sysjobschedules JS
                ON J.job_id = JS.job_id
        WHERE
            c.ItemID = S.Report_OID
    ) AS s
WHERE
    c.Type = 2 -- Report
    --and c.name = 'Report Name'
    --and DeliveryExtension = 'Report Server FileShare'
;
    
