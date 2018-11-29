

SELECT
    *
into #PowerBI
FROM dbadmin..WhoIsActiveStats
WHERE 1=1
    and collection_time >= dateadd(day, -7, getdate())
    AND host_name like 'PWSTCPOWERBI%'

create clustered index cix on #PowerBI (collection_time, session_id) with (data_compression=page)

SELECT
    session_id
,   host_name
,   login_name
,   program_name
,   start_time
,   max(collection_time) as end_time_approx
,   DATEDIFF(minute, start_time, max(collection_time)) as duration_min_approx
,   sql_text
FROM #PowerBI
WHERE 1=1
    and collection_time >= dateadd(day, -2, getdate())
    AND host_name like 'PWSTCPOWERBI%'
GROUP BY
    session_id
,   host_name
,   login_name
,   program_name
,   start_time
,   sql_text
HAVING
    DATEDIFF(minute, start_time, max(collection_time)) > 5
ORDER BY
    end_time_approx




--SELECT
--    session_id
--,   host_name
--,   login_name
--,   program_name
--,   start_time
--,   wait_info
--FROM dbadmin..WhoIsActiveStats
--WHERE 1=1
--    and collection_time >= dateadd(hour, -6, getdate())
--    AND host_name like 'PWSTCPOWERBI%'
--    --and sql_text like '(@0 int)select Clients . *%'
--    and session_id = 168
--order by
--    collection_time desc
