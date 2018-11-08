select 
	p.proname
,	ns.nspname as "namespace"
,	u.usename as owner_name
,	l.lanname
,	'alter function '||ns.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||') owner to protransport_10302_global_spedition_llc_user;'
from pg_proc AS p
join pg_language as l on l.oid = p.prolang
join pg_namespace as ns on ns.oid = p.pronamespace
join pg_user as u ON u.usesysid = p.proowner
where 1=1
 and p.proname like 'xll_%'
 and u.usename <> 'protransport_10302_global_spedition_llc_user'