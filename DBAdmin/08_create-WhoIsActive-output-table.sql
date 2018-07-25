USE DBAdmin;
GO

IF OBJECT_ID('dbo.WhoIsActiveStats') IS NULL
CREATE TABLE dbo.WhoIsActiveStats
(
 [collection_time]       DATETIME NOT NULL,
 [session_id]            INT NOT NULL, 
 [elapsed_time_s]		 INT NOT NULL,
 [status]                VARCHAR(30) NOT NULL,
 [blocking_session_id]   INT NULL, 
 [blocked_session_count] INT NULL, 
 [wait_info]             NVARCHAR(4000) NULL, 
 [database_name]         NVARCHAR(128) NULL, 
 [host_name]             NVARCHAR(128) NULL, 
 [login_name]            NVARCHAR(128) NOT NULL, 
 [program_name]          NVARCHAR(128) NULL, 
 [sql_text]              NVARCHAR(MAX) NULL, 
 [sql_command]           NVARCHAR(MAX) NULL, 
 [tran_log_writes]       NVARCHAR(4000) NULL, 
 [CPU]                   INT NULL, 
 [tempdb_allocations]    BIGINT NULL, 
 [tempdb_current]        BIGINT NULL, 
 [reads]                 BIGINT NULL, 
 [writes]                BIGINT NULL, 
 [physical_reads]        BIGINT NULL, 
 [query_plan]            XML NULL, 
 [used_memory]           BIGINT NOT NULL, 
 [tran_start_time]       DATETIME NULL, 
 [open_tran_count]       INT NULL, 
 [percent_complete]      REAL NULL, 
 [additional_info]       XML NULL, 
 [start_time]            DATETIME NOT NULL, 
 [login_time]            DATETIME NULL, 
 [request_id]            INT NULL
);

CREATE CLUSTERED INDEX CIX_WhoIsActiveStats ON dbo.WhoIsActiveStats (collection_time, session_id);
GO

CREATE NONCLUSTERED INDEX IX_LongestRunning ON dbo.WhoIsActiveStats (elapsed_time_s DESC);
GO
