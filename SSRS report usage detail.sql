USE ReportServer;
SELECT 
       [Path] = SUBSTRING(c.[Path], 1, LEN(c.[Path])-(CHARINDEX('/', REVERSE(c.[Path]))-1))
     , c.Name AS ReportName
     , [Hidden] = CASE
                      WHEN c.[Hidden] = 1
                      THEN 'Yes'
                      ELSE 'No'
                  END
     , [Last Executed] = CONVERT(VARCHAR, ISNULL(el.TimeStart, S.LastRunTime), 120)
     , [Next Scheduled] = msdb.dbo.agent_datetime(NULLIF(js.next_run_date, 0), NULLIF(js.next_run_time, 0))
     , S.[DeliveryExtension]
     --,  [ExtensionSettings]
     , [To] = CONVERT(XML, S.[ExtensionSettings]).value('(//ParameterValue/Value[../Name="TO"])[1]', 'nvarchar(max)')
     , [CC] = CONVERT(XML, S.[ExtensionSettings]).value('(//ParameterValue/Value[../Name="CC"])[1]', 'nvarchar(max)')
     , [File Share] = COALESCE(
                            CONVERT(XML, S.[ExtensionSettings]).value('(//ParameterValue/Value[../Name="PATH"])[1]', 'nvarchar(max)')
                        ,   CASE WHEN CONVERT(XML, S.[ExtensionSettings]).value('(//ParameterValue/Field[../Name="PATH"])[1]', 'nvarchar(max)') IS NOT NULL THEN 'Data Driven' END
                        )
     , [Render Format] = COALESCE(
                            CONVERT(XML, S.[ExtensionSettings]).value('(//ParameterValue/Value[../Name="RENDER_FORMAT"])[1]', 'nvarchar(50)')
                        ,   CONVERT(XML, S.[ExtensionSettings]).value('(//ParameterValue/Value[../Name="RenderFormat"])[1]', 'nvarchar(50)')
                        )
     --, [Subject] = CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="Subject"])[1]', 'nvarchar(max)')
---Example report parameters: StartDateMacro, EndDateMacro &amp; Currency.
     --, [Start Date] = CONVERT(XML, [Parameters]).value('(//ParameterValue/Value[../Name="StartDateMacro"])[1]', 'nvarchar(50)')
     --, [End Date] = CONVERT(XML, [Parameters]).value('(//ParameterValue/Value[../Name="EndDateMacro"])[1]', 'nvarchar(50)')
     --, [Currency] = CONVERT(XML, [Parameters]).value('(//ParameterValue/Value[../Name="Currency"])[1]', 'nvarchar(50)')
     , [Execution Result] = el.Status
     , S.[LastStatus]
     --, S.[EventType]

     --, S.[Version]
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
     LEFT JOIN dbo.[Subscriptions] S
        ON c.ItemID = S.Report_OID
     LEFT JOIN dbo.ReportSchedule R
        ON S.SubscriptionID = R.SubscriptionID
     LEFT JOIN msdb.dbo.sysjobs J
        ON CONVERT(NVARCHAR(128), R.ScheduleID) = J.name
     LEFT JOIN msdb.dbo.sysjobschedules JS
        ON J.job_id = JS.job_id
WHERE
    c.Type = 2 -- Report
    --and c.name = 'Report Name'
    --and DeliveryExtension = 'Report Server FileShare'
;

select top 10 * from executionlog3 where Status not in ( 'rsSuccess', 'rsProcessingAborted' )

SELECT
    [Path] = SUBSTRING(c.[Path], 1, LEN(c.[Path])-(CHARINDEX('/', REVERSE(c.[Path]))-1))
,   c.Name
,   [To] = STUFF((    SELECT distinct ';' + CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="TO"])[1]', 'nvarchar(50)') AS [text()]
                FROM dbo.[Subscriptions] AS s
                WHERE
                s.Report_OID = c.ItemID
                FOR XML PATH('')
                ), 1, 1, '' )
,   [CC] = STUFF((    SELECT distinct ';' + CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="CC"])[1]', 'nvarchar(50)') AS [text()]
                FROM dbo.[Subscriptions] AS s
                WHERE
                s.Report_OID = c.ItemID
                FOR XML PATH('')
                ), 1, 1, '' )

FROM
    dbo.[Catalog] AS c

select top 10 * from catalog


select top 10
    s.*
from subscriptions s
join catalog c on s.Report_OID = c.ItemID
where c.name = 'Report Name'