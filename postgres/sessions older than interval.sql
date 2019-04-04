select 
	  datname
	, usename
	, client_addr
	, query_start
	, waiting
	, state
	, state_change
	, NOW() - state_change AS time_in_state
	, query
from pg_stat_activity
where state_change < NOW() - INTERVAL '10 minutes'
order by state_change;