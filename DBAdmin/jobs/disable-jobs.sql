EXEC msdb.dbo.sp_update_job @job_name = 'Collect sp_WhoIsActive', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'Collect Database File IO Stats', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'Collect Database Storage Stats', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'Collect Wait Stats', @enabled = 0;