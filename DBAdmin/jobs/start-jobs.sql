EXEC msdb.dbo.sp_start_job @job_name = 'Collect Database File IO Stats';
EXEC msdb.dbo.sp_start_job @job_name = 'Collect Database Storage Stats';
EXEC msdb.dbo.sp_start_job @job_name = 'Collect Wait Stats';
EXEC msdb.dbo.sp_start_job @job_name = 'DBAdmin Purge Old Data';