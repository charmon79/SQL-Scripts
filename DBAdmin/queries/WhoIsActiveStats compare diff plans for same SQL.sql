use DBAdmin;
GO

drop table if exists #temp;

SELECT
    w.collection_time
,   w.session_id
,   w.database_name
,   w.program_name
,   w.cpu
,   w.tempdb_allocations
,   w.tempdb_current
,   w.used_memory
,   N.C.value('sql_handle[1]', 'varchar(128)') AS sql_handle
,   N.C.value('plan_handle[1]', 'varchar(128)') AS plan_handle
,   w.sql_text
,   w.query_plan
--sql_text, count(1)
INTO #temp
FROM
    dbadmin..WhoIsActiveStats AS w
    CROSS APPLY additional_info.nodes('//additional_info') N(C)
WHERE collection_time >= DATEADD(hour, -2, GETDATE())
      AND database_name NOT IN ('DBAdmin', 'distribution')
AND status <> 'sleeping'
AND program_name NOT IN ('SQLCMD')
--and used_memory > 1000000
--ORDER BY
--    collection_time DESC
--  , elapsed_time_s DESC;

CREATE CLUSTERED INDEX cix ON #temp (collection_time, session_id);
CREATE NONCLUSTERED INDEX ix_sqlhandle ON #temp (sql_handle) include (plan_handle);


select *
from #temp
--where collection_time >= dateadd(hour, -2, getdate())
order by collection_time;


WITH DistinctSQL
     AS (SELECT
             sql_handle
           , plan_handle
           , COUNT(1) AS plan_count
         FROM
             #temp
         GROUP BY
             sql_handle
           , plan_handle)
     SELECT
         ds.*
       , DENSE_RANK() OVER(ORDER BY ds.sql_handle) AS distinct_query_num
       , 'DBCC FREEPROCCACHE ('+ds.plan_handle+')' AS plan_killer
       , memuse.min_used_memory
       , memuse.max_used_memory
       , memuse.avg_used_memory
       , t.sql_text
       , t.query_plan
     FROM
         DistinctSQL AS ds
         CROSS APPLY
     (
         SELECT
             MIN(used_memory) AS min_used_memory
           , MAX(used_memory) AS max_used_memory
           , AVG(used_memory) AS avg_used_memory
         FROM
             #temp
         WHERE sql_handle = ds.sql_handle
               AND plan_handle = ds.plan_handle
         GROUP BY
             sql_handle
           , plan_handle
        --HAVING
        --    min(used_memory) > 1000000
     ) AS memuse
         CROSS APPLY
     (
         SELECT TOP 1
             sql_text
           , query_plan
         FROM
             #temp
         WHERE sql_handle = ds.sql_handle
               AND plan_handle = ds.plan_handle
     ) AS t
     WHERE
        1=1
        --AND EXISTS
        -- (
        --     SELECT
        --         1
        --     FROM
        --         #temp
        --     WHERE sql_handle = ds.sql_handle
        --           AND used_memory > 1000000
        -- )
        AND sql_handle IN (
         '0x020000007a1db700adf9bd96d0bab5f6580838e0b592d1430000000000000000000000000000000000000000'
        ,'0x02000000e4af512242ec329511150d7108c15ea8feff61bd0000000000000000000000000000000000000000'
        ,'0x02000000e4af512242ec329511150d7108c15ea8feff61bd0000000000000000000000000000000000000000'
        ,'0x02000000fb5c7500530158710bba52b3556b1a8b90e831da0000000000000000000000000000000000000000'
        )

;

/*
guides created for SQL which had these handles:
0x020000007a1db700adf9bd96d0bab5f6580838e0b592d1430000000000000000000000000000000000000000
0x02000000e4af512242ec329511150d7108c15ea8feff61bd0000000000000000000000000000000000000000
0x02000000e4af512242ec329511150d7108c15ea8feff61bd0000000000000000000000000000000000000000
0x02000000fb5c7500530158710bba52b3556b1a8b90e831da0000000000000000000000000000000000000000
*/