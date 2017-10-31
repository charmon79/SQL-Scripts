USE XPRT

SELECT
    DB_NAME() AS [Database]
,   s.name AS [Schema]
,   t.name AS [Table]
,   c.name AS [Column]
,   ty.name 
    +   CASE
            WHEN ty.name IN ('char','varchar')
                THEN CONCAT('(',ISNULL(CAST(NULLIF(c.max_length, -1) AS VARCHAR),'MAX'),')')
            WHEN ty.name IN ('nchar','nvarchar')
                THEN CONCAT('(',ISNULL(CAST(NULLIF(c.max_length, -1)/2 AS VARCHAR),'MAX'),')')
            WHEN ty.name IN ('binary','varbinary')
                THEN CONCAT('(',ISNULL(CAST(NULLIF(c.max_length, -1) AS VARCHAR),'MAX'),')')
            WHEN ty.name IN ('decimal','real')
                THEN CONCAT('(',c.precision,',',c.scale,')')
            WHEN ty.name IN ('datetime2','time')
                THEN CONCAT('(',c.scale,')')
            ELSE ''
        END
    AS [DataType]
,   c.is_identity AS [IsIdentity]
,   c.is_computed AS [IsComputed]
,   c.is_rowguidcol AS [IsRowGUID]
,   dc.definition AS [DefaultValue]
,   CASE c.default_object_id WHEN 0 THEN 0 ELSE 1 END AS HasDefault
,   '' AS [Ignore for XRS]
,   '' AS [XRS Table]
,   '' AS [XRS Column]
,   '' AS Comments
FROM
    sys.tables AS t
    JOIN sys.schemas AS s ON s.schema_id = t.schema_id
    JOIN sys.columns AS c ON c.object_id = t.object_id
    JOIN sys.types AS ty ON ty.system_type_id = c.system_type_id AND ty.system_type_id = ty.user_type_id
    LEFT JOIN sys.default_constraints AS dc ON dc.object_id = c.default_object_id
WHERE
    t.is_ms_shipped = 0
ORDER BY
    s.name
,   t.name
,   c.name