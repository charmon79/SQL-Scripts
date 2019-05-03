USE foobar;
GO

SELECT 
    *
INTO dbo.temp_trace_data_table
FROM fn_trace_gettable('somefile.trc', 1)
;

CREATE COLUMNSTORE INDEX ccix ON dbo.temp_trace_data_table (
NTUserName
,NTDomainName
,HostName
,ApplicationName
,LoginName
,SPID
,Duration
,StartTime
,EndTime
,Reads
,Writes
,CPU
,Severity
,EventSubClass
,Success
,ServerName
,EventClass
,ObjectType
,NestLevel
,State
,Error
,Mode
,Handle
,ObjectName
,DatabaseName
,RowCounts
,ParentName
,IsSystem
,SessionLoginName
)

select top 500 *
from dbo.temp_trace_data_table
order by EndTime
;

delete from temp_trace_data_table where TextData = 'exec sp_reset_connection '
delete from temp_trace_data_table where TextData like 'SET NO_BROWSETABLE %'

SELECT
    min(StartTime) AS StartTime
,   max(EndTime) AS EndTime
,   datediff(second, min(StartTime), max(EndTime)) AS trace_duration_s
,   count(1) as query_count
,   CAST(min(duration) / 1000.0 AS decimal(18,2)) as query_duration_ms_min
,   CAST(max(duration) / 1000.0 AS decimal(18,2)) as query_duration_ms_max
,   CAST(avg(duration) / 1000.0 AS decimal(18,2)) as query_duration_ms_avg
,   min(reads) as reads_min
,   max(reads) as reads_max
,   avg(reads) as reads_avg
from dbo.temp_trace_data_table
;

select top 10 *
from dbo.temp_trace_data_table
order by reads desc