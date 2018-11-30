select t.table_name, t.table_type, c.relname, c.relowner, u.usename
,'alter table public.'||t.table_name||' owner to <user name>;'
from information_schema.tables t
join pg_catalog.pg_class c on (t.table_name = c.relname)
join pg_catalog.pg_user u on (c.relowner = u.usesysid)
where t.table_schema='public'
and u.usename <> '<user name>'
and t.table_name not like 'pg_%'
;