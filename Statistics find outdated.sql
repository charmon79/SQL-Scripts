USE cadnceprd;
GO

SELECT
    s.name AS schema_name
,   o.name AS object_name
,   c.name AS column_name
,   st.name AS stats_name
,   stp.last_updated
,   stp.rows
,   stp.rows_sampled
,   (stp.rows_sampled / (1.0 * stp.rows)) * 100.0 AS sample_percent
,   stp.modification_counter
,   ((1.0 * stp.modification_counter) / stp.rows) * 100 AS percent_modified
FROM
    sys.objects AS o
    JOIN sys.schemas AS s ON s.schema_id = o.schema_id
    --JOIN sys.indexes AS i ON i.object_id = o.object_id
    JOIN sys.stats AS st ON st.object_id = o.object_id
    JOIN sys.stats_columns AS stc ON stc.object_id = st.object_id and stc.stats_id = st.stats_id
    JOIN sys.columns AS c ON c.object_id = stc.object_id and c.column_id = stc.column_id
    CROSS APPLY sys.dm_db_stats_properties (o.object_id, st.stats_id) stp
WHERE
    1=1
    and o.is_ms_shipped = 0
    --and o.name IN (
    --    'orders'
    --)
    --and c.name IN (
    --    'company_id'
    --)
    --AND (1.0 * stp.modification_counter) / stp.rows >= 0.01 -- at least 1% of rows changed
ORDER BY
    modification_counter DESC

