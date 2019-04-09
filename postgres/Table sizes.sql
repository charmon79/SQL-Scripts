select
    c.oid
    ,   t.*
,   c.relpages -- only an estimate
,   c.reltuples -- only an estimate
,   pg_size_pretty(pg_table_size(c.oid)) AS table_size
from
    pg_class AS c
    JOIN pg_namespace AS ns ON ns.oid = c.relnamespace
    JOIN pg_tables AS t ON t.tablename = c.relname AND t.schemaname = ns.nspname
where
    ns.nspname not in ('pg_catalog','pg_toast','information_schema')
order by
    pg_table_size(c.oid) desc;