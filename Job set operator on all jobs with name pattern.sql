DECLARE @jobId uniqueidentifier;
DECLARE @JobIDs table (job_id uniqueidentifier primary key);

-- get job IDs of the jobs we want to use the operator @operator_id
INSERT @JobIDs
SELECT
    job_id
FROM
    msdb.dbo.sysjobs
WHERE
    name LIKE 'DatabaseBackup %'
;

-- apply operator to jobs
DECLARE cur_jobs CURSOR LOCAL FAST_FORWARD FOR
    SELECT job_id from @JobIDs;
OPEN cur_jobs;
FETCH NEXT FROM cur_jobs INTO @jobId;
WHILE @@FETCH_STATUS = 0
BEGIN
    EXEC msdb.dbo.sp_update_job
        @job_id = @jobId
    ,   @notify_level_email = 2 -- on failure
    ,   @notify_email_operator_name = 'DBA Non-Critical'
    ;
    FETCH NEXT FROM cur_jobs INTO @jobId;
END
CLOSE cur_jobs;
DEALLOCATE cur_jobs;

