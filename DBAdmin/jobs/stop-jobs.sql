EXEC msdb.dbo.sp_stop_job @job_name = 'Collect sp_WhoIsActive';
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect Database File IO Stats';
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect Database Storage Stats';
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect Wait Stats';