SELECT
	  datname
	, usename
	, state
	, count(1)
from pg_stat_activity
group by
	  datname
	, usename
    , state
order by
	count(1) desc
  , state
  , datname
  , usename;