USE LME;
GO

SELECT
    sc.name AS schema_name
,   o.name AS object_name
,   s.name AS stats_name
,   sp.last_updated
,   sp.rows
,   sp.modification_counter
,   ((1.0 * sp.modification_counter) / sp.rows) * 100 AS percent_modified
FROM
    sys.objects AS o
    JOIN sys.schemas AS sc ON sc.schema_id = o.schema_id
    --JOIN sys.indexes AS i ON i.object_id = o.object_id
    JOIN sys.stats AS s ON s.object_id = o.object_id
    CROSS APPLY sys.dm_db_stats_properties (o.object_id, s.stats_id) sp
WHERE
    1=1
    --and o.name IN (
    --    'CheckDtl'
    --,   'CheckHdr'
    --,   'Payments'
    --,   'Transactions'
    --,   'Accounts'
    --,   'Expenses'
    --)
    AND (1.0 * sp.modification_counter) / sp.rows >= 0.01 -- at least 1% of rows changed
ORDER BY
    modification_counter DESC

