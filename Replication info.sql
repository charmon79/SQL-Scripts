--********** Execute at the Publisher in the master database **********--  

IF OBJECT_ID('tempdb..#ReplDBOption') IS NOT NULL DROP TABLE #ReplDBOption;
CREATE TABLE #ReplDBOption (
    name sysname not null
,   id int not null
,   transpublish bit
,   mergepublish bit
,   dbowner bit
,   dbreadonly bit
);

--Which databases are published for replication and what type of replication?  
INSERT #ReplDBOption
EXEC sp_helpreplicationdboption;  

SELECT *
FROM #ReplDBOption
WHERE transpublish = 1 OR mergepublish = 1;

SELECT name, is_published, is_merge_published
from sys.databases
where is_published = 1 or is_merge_published = 1;

--What are the properties for Subscribers that subscribe to publications at this Publisher?  
EXEC sp_helpsubscriberinfo;  