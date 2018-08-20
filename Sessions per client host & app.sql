use dbadmin;

select top 50
    *
from
    dbo.whoisactivestats
where
    collection_time >= cast(getdate() as date)
    and program_name = 'CADENCE Reports'


select *
from sys.dm_exec_sessions


select
    s.session_id
,	s.login_time
,	s.last_request_start_time
,	s.last_request_end_time
,	s.login_name
,	s.host_name
,	s.program_name
,	s.database_id
,   d.name as database_name
,   c.*
from sys.dm_exec_connections c
    join sys.dm_exec_sessions s on s.session_id = c.session_id
    LEFT JOIN sys.databases AS d ON d.database_id = s.database_id
order by last_request_end_time


select
    s.host_name
,   s.login_name
,   s.program_name
,   count(1) as session_count
from sys.dm_exec_connections c
    join sys.dm_exec_sessions s on s.session_id = c.session_id
    LEFT JOIN sys.databases AS d ON d.database_id = s.database_id
--order by last_request_end_time
group by
    s.host_name
,   s.login_name
,   s.program_name
order by
    session_count desc
;