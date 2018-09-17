-- count of sessions
SELECT COUNT(1)
from pg_stat_activity
where state = 'idle'
and state_change < NOW() - INTERVAL '1 hour';

-- list sessions
select 
	  datname
	, usename
	, client_addr
	, query_start
	, waiting
	, state
	, state_change
	, query
from pg_stat_activity
where state_change < NOW() - INTERVAL '1 hour'
order by state_change;

-- sessions by user
SELECT usename, state, count(1) from pg_stat_activity group by usename, state order by 3 desc, 2, 1;