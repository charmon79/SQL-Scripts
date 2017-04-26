
/* sysjobs */
INSERT msdb.dbo.sysjobs
        (
         job_id
       , originating_server_id
       , name
       , enabled
       , description
       , start_step_id
       , category_id
       , owner_sid
       , notify_level_eventlog
       , notify_level_email
       , notify_level_netsend
       , notify_level_page
       , notify_email_operator_id
       , notify_netsend_operator_id
       , notify_page_operator_id
       , delete_level
       , date_created
       , date_modified
       , version_number
        )
SELECT
    oj.job_id
  , oj.originating_server_id
  , oj.name
  , oj.enabled
  , oj.description
  , oj.start_step_id
  , oj.category_id
  , oj.owner_sid
  , oj.notify_level_eventlog
  , oj.notify_level_email
  , oj.notify_level_netsend
  , oj.notify_level_page
  , oj.notify_email_operator_id
  , oj.notify_netsend_operator_id
  , oj.notify_page_operator_id
  , oj.delete_level
  , oj.date_created
  , oj.date_modified
  , oj.version_number
FROM
    msdb_OLD.dbo.sysjobs AS oj
    LEFT JOIN msdb.dbo.sysjobs AS j ON oj.name = j.name
WHERE
    j.name IS NULL

/* sysjobsteps */
INSERT  msdb.dbo.sysjobsteps
        (
         job_id
       , step_id
       , step_name
       , subsystem
       , command
       , flags
       , additional_parameters
       , cmdexec_success_code
       , on_success_action
       , on_success_step_id
       , on_fail_action
       , on_fail_step_id
       , server
       , database_name
       , database_user_name
       , retry_attempts
       , retry_interval
       , os_run_priority
       , output_file_name
       , last_run_outcome
       , last_run_duration
       , last_run_retries
       , last_run_date
       , last_run_time
       , proxy_id
       , step_uid
        )
SELECT  
    ojs.job_id
  , ojs.step_id
  , ojs.step_name
  , ojs.subsystem
  , ojs.command
  , ojs.flags
  , ojs.additional_parameters
  , ojs.cmdexec_success_code
  , ojs.on_success_action
  , ojs.on_success_step_id
  , ojs.on_fail_action
  , ojs.on_fail_step_id
  , ojs.server
  , ojs.database_name
  , ojs.database_user_name
  , ojs.retry_attempts
  , ojs.retry_interval
  , ojs.os_run_priority
  , ojs.output_file_name
  , ojs.last_run_outcome
  , ojs.last_run_duration
  , ojs.last_run_retries
  , ojs.last_run_date
  , ojs.last_run_time
  , ojs.proxy_id
  , ojs.step_uid
FROM
    msdb_OLD.dbo.sysjobsteps AS ojs
    LEFT JOIN msdb.dbo.sysjobsteps AS js ON js.job_id = ojs.job_id
WHERE
    js.job_id IS NULL 

/* sysjobschedules */
SET IDENTITY_INSERT msdb.dbo.sysschedules ON;
INSERT msdb.dbo.sysschedules
        (
         schedule_id
       , schedule_uid
       , originating_server_id
       , name
       , owner_sid
       , enabled
       , freq_type
       , freq_interval
       , freq_subday_type
       , freq_subday_interval
       , freq_relative_interval
       , freq_recurrence_factor
       , active_start_date
       , active_end_date
       , active_start_time
       , active_end_time
       , date_created
       , date_modified
       , version_number
        )
SELECT
    os.schedule_id
  , os.schedule_uid
  , os.originating_server_id
  , os.name
  , os.owner_sid
  , os.enabled
  , os.freq_type
  , os.freq_interval
  , os.freq_subday_type
  , os.freq_subday_interval
  , os.freq_relative_interval
  , os.freq_recurrence_factor
  , os.active_start_date
  , os.active_end_date
  , os.active_start_time
  , os.active_end_time
  , os.date_created
  , os.date_modified
  , os.version_number
FROM
    msdb_OLD.dbo.sysschedules AS os
    LEFT JOIN msdb.dbo.sysschedules AS s ON s.schedule_uid = os.schedule_uid
WHERE
    s.schedule_id IS NULL
    AND NOT EXISTS (
        SELECT *
        FROM msdb.dbo.sysschedules AS s2
        WHERE s2.name = os.name
    )
;
SET IDENTITY_INSERT msdb.dbo.sysschedules OFF;

/* sysjobschedules */
INSERT INTO msdb.dbo.sysjobschedules
        (
         schedule_id
       , job_id
       , next_run_date
       , next_run_time
        )
SELECT
    ojs.schedule_id
  , ojs.job_id
  , ojs.next_run_date
  , ojs.next_run_time
  --, j.job_id
FROM
    msdb_OLD.dbo.sysjobschedules AS ojs
    JOIN msdb_OLD.dbo.sysjobs AS oj ON oj.job_id = ojs.job_id
    LEFT JOIN msdb.dbo.sysjobschedules AS js ON js.job_id = ojs.job_id
    LEFT JOIN msdb.dbo.sysjobs AS j ON j.job_id = oj.job_id
WHERE
    js.job_id IS NULL
    AND j.job_id IS NOT NULL
;



/* sysjobhistory */
INSERT msdb.dbo.sysjobhistory
        (
         job_id
       , step_id
       , step_name
       , sql_message_id
       , sql_severity
       , message
       , run_status
       , run_date
       , run_time
       , run_duration
       , operator_id_emailed
       , operator_id_netsent
       , operator_id_paged
       , retries_attempted
       , server
        )
SELECT
    oh.job_id
  , oh.step_id
  , oh.step_name
  , oh.sql_message_id
  , oh.sql_severity
  , oh.message
  , oh.run_status
  , oh.run_date
  , oh.run_time
  , oh.run_duration
  , oh.operator_id_emailed
  , oh.operator_id_netsent
  , oh.operator_id_paged
  , oh.retries_attempted
  , oh.server
FROM
    msdb_OLD.dbo.sysjobhistory AS oh

SELECT * FROM msdb.dbo.sysschedules AS s
SELECT * FROM msdb.dbo.sysjobschedules AS s

SELECT
    *
FROM    
    msdb.dbo.sysjobschedules AS js
    LEFT JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
    LEFT JOIN msdb.dbo.sysjobs AS j ON j.job_id = js.job_id


/* sysjobservers */
INSERT msdb.dbo.sysjobservers
        (
         job_id
       , server_id
       , last_run_outcome
       , last_outcome_message
       , last_run_date
       , last_run_time
       , last_run_duration
        )
SELECT
    os.job_id
  , os.server_id
  , os.last_run_outcome
  , os.last_outcome_message
  , os.last_run_date
  , os.last_run_time
  , os.last_run_duration
FROM
    msdb_OLD.dbo.sysjobservers AS os
    LEFT JOIN msdb.dbo.sysjobservers AS s ON s.job_id = os.job_id
WHERE
    s.job_id IS NULL



