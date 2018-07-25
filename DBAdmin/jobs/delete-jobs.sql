-- disable jobs
EXEC msdb.dbo.sp_update_job @job_name = 'Collect sp_WhoIsActive', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'Collect Database File IO Stats', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'Collect Database Storage Stats', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'Collect Wait Stats', @enabled = 0;
EXEC msdb.dbo.sp_update_job @job_name = 'DBAdmin Purge Old Data', @enabled = 0;

-- stop jobs
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect sp_WhoIsActive';
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect Database File IO Stats';
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect Database Storage Stats';
EXEC msdb.dbo.sp_stop_job @job_name = 'Collect Wait Stats';
EXEC msdb.dbo.sp_stop_job @job_name = 'DBAdmin Purge Old Data';

-- delete jobs
EXEC msdb.dbo.sp_delete_job @job_name = 'Collect sp_WhoIsActive', @delete_unused_schedule = 1, @delete_history = 1;
EXEC msdb.dbo.sp_delete_job @job_name = 'Collect Database File IO Stats', @delete_unused_schedule = 1, @delete_history = 1;
EXEC msdb.dbo.sp_delete_job @job_name = 'Collect Database Storage Stats', @delete_unused_schedule = 1, @delete_history = 1;
EXEC msdb.dbo.sp_delete_job @job_name = 'Collect Wait Stats', @delete_unused_schedule = 1, @delete_history = 1;
EXEC msdb.dbo.sp_delete_job @job_name = 'DBAdmin Purge Old Data', @delete_unused_schedule = 1, @delete_history = 1;
