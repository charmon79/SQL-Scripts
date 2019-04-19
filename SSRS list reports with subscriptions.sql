USE ReportServer;
SELECT 
       [Path] = SUBSTRING(c.[Path], 1, LEN(c.[Path])-(CHARINDEX('/', REVERSE(c.[Path]))-1))
     , c.Name AS ReportName
     , [Hidden] = CASE
                      WHEN c.[Hidden] = 1
                      THEN 'Yes'
                      ELSE 'No'
                  END
     , [Last Executed] = CONVERT(VARCHAR, el.TimeStart, 120)
     , [Next Scheduled] = msdb.dbo.agent_datetime(NULLIF(js.next_run_date, 0), NULLIF(js.next_run_time, 0))
     , [To] = CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="TO"])[1]', 'nvarchar(50)')
     , [CC] = CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="CC"])[1]', 'nvarchar(50)')
     , [Render Format] = CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="RenderFormat"])[1]', 'nvarchar(50)')
     , [Subject] = CONVERT(XML, [ExtensionSettings]).value('(//ParameterValue/Value[../Name="Subject"])[1]', 'nvarchar(50)')
---Example report parameters: StartDateMacro, EndDateMacro &amp; Currency.
     , [Start Date] = CONVERT(XML, [Parameters]).value('(//ParameterValue/Value[../Name="StartDateMacro"])[1]', 'nvarchar(50)')
     , [End Date] = CONVERT(XML, [Parameters]).value('(//ParameterValue/Value[../Name="EndDateMacro"])[1]', 'nvarchar(50)')
     , [Currency] = CONVERT(XML, [Parameters]).value('(//ParameterValue/Value[../Name="Currency"])[1]', 'nvarchar(50)')
     , [LastStatus]
     , [EventType]
     , [LastRunTime]
     , [DeliveryExtension]
     , [Version]
FROM 
     dbo.[Catalog] c
     OUTER APPLY
    (
        SELECT 
                MAX(TimeStart) AS TimeStart
        FROM 
                dbo.ExecutionLog
        WHERE ReportID = c.ItemID
    ) AS el
     LEFT JOIN dbo.[Subscriptions] S
        ON c.ItemID = S.Report_OID
     LEFT JOIN dbo.ReportSchedule R
        ON S.SubscriptionID = R.SubscriptionID
     LEFT JOIN msdb.dbo.sysjobs J
        ON CONVERT(NVARCHAR(128), R.ScheduleID) = J.name
     LEFT JOIN msdb.dbo.sysjobschedules JS
        ON J.job_id = JS.job_id
;