WITH cte_blocked AS (
SELECT 
     blocked_locks.pid         AS blocked_pid,
       blocked_activity.usename  AS blocked_user,
     now() - blocked_activity.query_start
                             AS blocked_duration,
       blocking_locks.pid        AS blocking_pid,
       blocking_activity.usename AS blocking_user,
     now() - blocking_activity.query_start
                                 AS blocking_duration,
       blocked_activity.query    AS blocked_statement,
       blocking_activity.query   AS blocking_statement
FROM pg_catalog.pg_locks AS blocked_locks
JOIN pg_catalog.pg_stat_activity AS blocked_activity
    ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks AS blocking_locks 
    ON blocking_locks.locktype = blocked_locks.locktype
        AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
        AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
        AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
        AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
        AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
        AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
        AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
        AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
        AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
        AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity AS blocking_activity
    ON blocking_activity.pid = blocking_locks.pid
WHERE 
  NOT blocked_locks.granted
)
select
  'LEAD BLOCKER' AS Blocking_Status
, NOW() - a.xact_start AS xact_duration
, NOW() - a.state_change AS time_in_state
, cte.blocked_count
, a.datname
, a.pid
, a.client_addr
, a.waiting
, a.state
, a.query
FROM
  pg_stat_database db
  JOIN pg_stat_activity a ON a.datid = db.datid
  JOIN (
    SELECT blocking_pid, count(1) as blocked_count
    FROM cte_blocked
    GROUP BY blocking_pid
  ) cte ON cte.blocking_pid = a.pid
WHERE 1=1
  --AND a.xact_start <= NOW() - INTERVAL '20 minutes'
  AND NOT a.waiting
order by xact_duration desc
;