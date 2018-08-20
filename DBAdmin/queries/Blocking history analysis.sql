USE DBAdmin;

DECLARE @cutoffTime datetime = dateadd(hour, -3, getdate());

WITH Blocking AS (
    SELECT *
    FROM dbadmin..WhoIsActiveStats
    WHERE collection_time >= @cutoffTime
            AND database_name NOT IN ('DBAdmin', 'distribution')
            --AND status <> 'sleeping'
            and (blocking_session_id is null and blocked_session_count > 0)
    UNION ALL
    SELECT *
    FROM dbadmin..WhoIsActiveStats
    WHERE collection_time >= @cutoffTime
            AND database_name NOT IN ('DBAdmin', 'distribution')
            --AND status <> 'sleeping'
            and (blocking_session_id is not null)
)
SELECT *
FROM Blocking
--where collection_time = '2018-08-02 07:49:00.863'
ORDER BY  collection_time desc, blocked_session_count desc, blocking_session_id
