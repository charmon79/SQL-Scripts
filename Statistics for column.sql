SELECT
    t.name
,   c.name
,   st.name
,   sth.step_number
,   sth.range_high_key
,   sth.range_rows
,   sth.equal_rows
,   sth.distinct_range_rows
,   sth.average_range_rows
FROM
    sys.tables AS t
    JOIN sys.columns AS c ON c.object_id = t.object_id
    JOIN sys.stats_columns AS stc ON stc.object_id = t.object_id AND stc.column_id = c.column_id
    JOIN sys.stats AS st ON st.stats_id = stc.stats_id
    CROSS APPLY sys.dm_db_stats_histogram(t.object_id, st.stats_id) sth
WHERE
    t.name = 'Expenses'
    AND c.name = 'AcctNo'
;