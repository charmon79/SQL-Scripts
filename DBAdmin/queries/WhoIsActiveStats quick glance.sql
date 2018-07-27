SELECT *
FROM dbadmin..WhoIsActiveStats
WHERE collection_time >= dateadd(hour, -2, getdate())
        AND database_name NOT IN ('DBAdmin', 'distribution')
        AND status <> 'sleeping'
ORDER BY  collection_time desc, elapsed_time_s desc