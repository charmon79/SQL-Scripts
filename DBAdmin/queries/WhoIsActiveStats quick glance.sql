SELECT *
FROM dbadmin..WhoIsActiveStats
WHERE 
    collection_time >= dateadd(hour, -1, getdate())
    --collection_time between '2018-12-05 02:30 AM' and '2018-12-05 7:30 AM'
        AND database_name NOT IN ('DBAdmin', 'distribution')
        AND status <> 'sleeping'
        --and elapsed_time_s > 300
ORDER BY  collection_time desc, elapsed_time_s desc