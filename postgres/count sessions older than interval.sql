-- count of sessions
SELECT COUNT(1)
from pg_stat_activity
where state = 'idle'
and state_change < NOW() - INTERVAL '10 minutes';