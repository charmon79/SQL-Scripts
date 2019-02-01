with cteGrowthFinder AS (

SELECT
    CollectedTime
,   DatabaseName
,   FileName
,   PhysicalName
,   SizeMB
,   FreeMB
,   SizeMB - ISNULL(LAG(SizeMB, 1) OVER (PARTITION BY DatabaseName, FileName ORDER BY CollectedTime), SizeMB) AS DayGrowth
FROM
    DBAdmin.dbo.DatabaseFileSizes
WHERE
    CollectedTime >= DATEADD(day, -14, getdate())

)

select * from cteGrowthFinder where DayGrowth > 0