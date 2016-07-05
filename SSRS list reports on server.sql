USE ReportServer;

SELECT  SUBSTRING([Path], 1, LEN([Path]) - (CHARINDEX('/', REVERSE([Path])) - 1)) AS [Path]
      , [Name]
      , [Description]
      , CASE WHEN [Hidden] = 1 THEN 'Yes'
             ELSE 'No'
        END AS [Hidden]
FROM    dbo.Catalog
WHERE   [Type] = 2
ORDER BY SUBSTRING([Path], 1, LEN([Path]) - (CHARINDEX('/', REVERSE([Path])) - 1))
      , [Name];