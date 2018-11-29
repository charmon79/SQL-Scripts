USE msdb;
GO

CREATE TABLE dbo.JobRunners (
    job_name NVARCHAR(128) NOT NULL
,   principal_name NVARCHAR(256) NOT NULL
,   CONSTRAINT PK_msdbJobRunners PRIMARY KEY CLUSTERED (job_name, principal_name)
);
GO

INSERT INTO dbo.JobRunners
--VALUES ('Limited User Job Runner Test', 'job_runner');
VALUES ('Limited User Job Runner Test', 'RYANRTS\Technical Support Analyst');
GO

INSERT INTO dbo.JobRunners VALUES ('pkgLoadMaster_Deliver_FabconInvoiceDetails_v2', 'RYANRTS\Technical Support Analyst');

IF OBJECT_ID('dbo.StartAgentJob') IS NULL EXEC ('CREATE PROC dbo.StartAgentJob AS RETURN;')
GO
ALTER PROCEDURE dbo.StartAgentJob
    @job_name NVARCHAR(128)
WITH EXECUTE AS OWNER
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @CurrentUser nvarchar(128);
    SET @CurrentUser = SUSER_SNAME();

    DECLARE @Allowed BIT;
    SET @Allowed = 0;

    --PRINT 'Starting user is: ' + USER_NAME();

    EXECUTE AS CALLER;
    --PRINT 'Switched context to user: ' + USER_NAME();
    IF EXISTS (
        SELECT 1
        FROM dbo.JobRunners
        WHERE job_name = @Job_Name
            AND (
                    IS_MEMBER(principal_name) = 1 -- user belongs to Windows group or SQL role which can run the job
                    OR principal_name = SUSER_SNAME() -- user itself can run the job
                )
        )
       SET @Allowed = 1;
    REVERT;

    --PRINT 'Reverted context to user: ' + USER_NAME();

    IF @Allowed = 1 
    EXEC dbo.sp_start_job @job_name = @Job_Name;
    ELSE
        RAISERROR('User [%s] does not have permission to start job [%s].', 16, 1, @CurrentUser, @job_name);
    RETURN;

END

GO

CREATE LOGIN [RYANRTS\Technical Support Analyst] FROM WINDOWS;
GO

CREATE USER [RYANRTS\Technical Support Analyst] FOR LOGIN [RYANRTS\Technical Support Analyst];

EXEC sp_addrolemember 'SQLAgentReaderRole', 'RYANRTS\Technical Support Analyst';

GRANT EXECUTE ON dbo.StartAgentJob TO [RYANRTS\Technical Support Analyst];

GO

