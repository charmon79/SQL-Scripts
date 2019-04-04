-- CREATE EXTENSION pgstattuple; -- need this to analyse logical b-tree fragmentation

select * from pgstattuple(21679);
select * from pgstatindex(21679);

select
    c.oid
,   am.amname
,   ns.nspname
,   c.relname
,   c.reltype
,   c.relpages -- only an estimate
,   c.reltuples -- only an estimate
,   pg_relation_size(c.oid) AS relation_size
,   i.index_size
,   i.avg_leaf_density
,   i.leaf_fragmentation
-- ,   c.*
from
    pg_class AS c
    join pg_am AS am ON am.oid = c.relam
    join pg_namespace AS ns ON ns.oid = c.relnamespace
    left join pgstatindex(c.oid) AS i ON true
WHERE 1=1
    AND c.reltype = 0 -- indexes
    AND ns.nspname not in ('pg_catalog','pg_toast')
limit 100
;


