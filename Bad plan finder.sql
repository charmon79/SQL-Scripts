

use dbadmin;
go

/*
--create schema adhoc authorization dbo;
--go
drop table if exists adhoc.CadenceBadPlans;
GO
create table adhoc.CadenceBadPlans (
    query_hash binary(8) null
,   query_plan_hash binary(8) not null
,   query_plan xml
,   query_text nvarchar(max)
,   min_grant_kb bigint
,   max_grant_kb bigint
);
go
ALTER TABLE adhoc.CadenceBadPlans ADD CONSTRAINT PK_CadenceBadPlans PRIMARY KEY CLUSTERED (query_plan_hash)
*/

insert adhoc.CadenceBadPlans (
    query_hash
,   query_plan_hash
,   query_plan
,   query_text
,   min_grant_kb
,   max_grant_kb
)
SELECT
    qs.query_hash
,   qs.query_plan_hash
,   qp.query_plan
,   st.text as query_text
--,   qs.creation_time
--,   qs.last_execution_time
--,   qs.execution_count
--,   (qs.total_grant_kb / qs.execution_count) AS avg_grant_kb
,   qs.min_grant_kb
,   qs.max_grant_kb
FROM
    sys.dm_exec_query_stats AS qs
    cross apply sys.dm_exec_query_plan(qs.plan_handle) AS qp
    cross apply sys.dm_exec_sql_text(qs.sql_handle) as st
    left join dbadmin.adhoc.CadenceBadPlans AS cp on cp.query_plan_hash = qs.query_plan_hash
WHERE
    1=1
    --and qs.query_plan_hash not IN ( 
    ---- fingerprints of known problem query plans
    --    0x46283E3E28FA3FB0
    --,   0xB298CA044B84625D
    --,   0x46283E3E28FA3FB0
    --,   0x7323D383B98AAD8E
    --,   0x2877C96F6C3FC5E4
    --,   0x3FEB7067693E4897
    --)
    AND (qs.total_grant_kb) / qs.execution_count > 1000000 -- only if they're asking for > 1GB memory (the next-worst queries are in the 150-500 MB range)
    AND execution_count > 2
    AND cp.query_plan_hash IS NULL
;