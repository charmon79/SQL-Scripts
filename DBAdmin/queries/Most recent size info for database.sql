USE DBAdmin;
GO

DECLARE @DatabaseName sysname;
SET @DatabaseName = 'DBAdmin';

SELECT *
FROM dbo.DatabaseFileSizes
WHERE DatabaseName = @DatabaseName
      AND CollectedTime =
        (
            SELECT MAX(CollectedTime)
            FROM dbo.DatabaseFileSizes
            WHERE DatabaseName = @DatabaseName
        )
;

SELECT *
FROM dbo.DatabaseTableSizes
WHERE DatabaseName = @DatabaseName
      AND CollectedTime =
        (
            SELECT MAX(CollectedTime)
            FROM dbo.DatabaseTableSizes
            WHERE DatabaseName = @DatabaseName
        )
ORDER BY ReservedMB DESC;