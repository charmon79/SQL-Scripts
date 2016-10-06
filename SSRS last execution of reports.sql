USE ReportServer;

SELECT
    SUBSTRING([Path], 1, LEN([Path]) - (CHARINDEX('/', REVERSE([Path])) - 1)) AS [Path]
,   c.Name
--,   c.Description
,   CASE WHEN [Hidden] = 1 THEN 'Yes'
            ELSE 'No'
    END AS [Hidden]
,   '??' AS Needed
,   '' AS [Description]
,   '' AS UsedBy
,   CONVERT(VARCHAR, MAX(el.TimeStart), 120) AS LastExecutedTime
FROM    dbo.Catalog AS c
        LEFT JOIN dbo.ExecutionLog AS el ON c.ItemID = el.ReportID
WHERE   c.Type = 2 -- 2 = Report
GROUP BY Path
       , c.Name
       , c.Description
       , [Hidden]
ORDER BY Path
       , c.Name
;

