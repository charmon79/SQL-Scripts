SELECT
    *
FROM
    DBAdmin.dbo.DatabaseTableSizes
WHERE
    CollectedTime >= CAST(getdate() as date)
    AND DatabaseName = DB_NAME()
ORDER BY
    DataMB desc