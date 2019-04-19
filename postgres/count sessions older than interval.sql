SELECT *, NOW() - state_change AS age
from pg_stat_activity
where state = 'idle'
and state_change < NOW() - INTERVAL '10 minutes';