-- CREATE EXTENSION pgstattuple; -- need this to analyse logical b-tree fragmentation

select
    i.indexrelid
,   am.amname
,   ns.nspname
,   tc.relname AS tablename
,   ic.relname AS indexname
,   ic.reltype
,   ic.relpages -- only an estimate
,   ic.reltuples -- only an estimate
,   pg_relation_size(i.indexrelid) AS relation_size
,   si.index_size
,   si.avg_leaf_density
,   si.leaf_fragmentation
-- ,   c.*
from
    pg_index AS i
    JOIN pg_class AS ic ON ic.oid = i.indexrelid
    JOIN pg_class AS tc ON tc.oid = i.indrelid
    JOIN pg_am AS am ON am.oid = ic.relam
    JOIN pg_namespace AS ns ON ns.oid = ic.relnamespace
    LEFT JOIN pgstatindex(i.indexrelid) AS si ON true
WHERE 1=1
--     AND c.reltype = 0 -- indexes
    AND am.amname = 'btree'
    AND ns.nspname not in ('pg_catalog','pg_toast')
    AND ic.relpages >= 10
-- ORDER BY
--     si.leaf_fragmentation desc
-- LIMIT 100
;
