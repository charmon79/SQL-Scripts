USE [msdb]
GO

declare @job_id UNIQUEIDENTIFIER;
declare @schedule_id int;

SET @job_id = (SELECT job_id FROM msdb.dbo.sysjobs WHERE name = 'Output File Cleanup');
SET @schedule_id = (select top 1 schedule_id from msdb.dbo.sysschedules where name = 'Daily @ 12:00 AM' and enabled = 1);

if @job_id is not null
begin

EXEC msdb.dbo.sp_update_job @job_id=@job_id, 
		@enabled=1

EXEC msdb.dbo.sp_attach_schedule @job_id=@job_id,@schedule_id=@schedule_id;

EXEC msdb.dbo.sp_start_job @job_id=@job_id;

END

