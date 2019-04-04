SELECT
    database_name
,   host_name
,   login_name
,   program_name
,   count(1) as TimesSeen
,   sum(ca
FROM dbadmin..WhoIsActiveStats
WHERE 
    collection_time >= dateadd(hour, -24, getdate())
    --collection_time between '2018-12-05 02:30 AM' and '2018-12-05 7:30 AM'
        AND database_name NOT IN ('DBAdmin', 'distribution')
        --and database_name = 'CADNCEPRD'
        --and host_name = 'pwcadapp03'
        AND status <> 'sleeping'
        --and elapsed_time_s > 300

group by
    database_name
,   host_name
,   login_name
,   program_name
order by 
    6 DESC