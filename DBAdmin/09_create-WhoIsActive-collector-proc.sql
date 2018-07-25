USE DBAdmin;
GO

IF OBJECT_ID('dbo.Collect_WhoIsActive') IS NULL
	EXEC('CREATE PROCEDURE dbo.Collect_WhoIsActive AS RETURN');
GO
ALTER PROCEDURE dbo.Collect_WhoIsActive
AS

BEGIN
	SET NOCOUNT ON;

	/*
		Catch results in a temp table first, because we're adding an elapsed_time_s calculated
		column to the results. (Adam Machanic returns a text representation of the duration when
		@format_output = 1, but not when @format_output = 0. (I want to use @format_output = 0
		so that important metrics are stored in their raw numeric form, not formatted text.)
	*/
	CREATE TABLE #ResultsTemp
	([collection_time]       DATETIME NOT NULL,
	 [session_id]            INT NOT NULL, 
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

	EXEC sp_WhoIsActive
		@get_transaction_info = 1
	,	@get_outer_command = 1
	,	@get_full_inner_text = 1
	,	@get_plans = 1
	,	@find_block_leaders = 1
	,	@get_additional_info = 2
	,	@format_output = 0
	,	@output_column_list = '[collection_time][session_id][duration][status][blocking_session_id][blocked_session_count][wait_info][database_name][host_name][login_name][program_name][sql_text][sql_command][tran_log_writes][CPU][tempdb_allocations][tempdb_current][reads][writes][physical_reads][query_plan][used_memory][tran_start_time][open_tran_count][percent_complete][additional_info][start_time][login_time][request_id]'
	,	@destination_table = '#ResultsTemp'
	;

	INSERT INTO dbo.WhoIsActiveStats
	SELECT
		collection_time
	,	DATEDIFF(second, start_time, collection_time) AS elapsed_time_s
	,	session_id
	,	[status]
	,	blocking_session_id
	,	blocked_session_count
	,	wait_info
	,	[database_name]
	,	[host_name]
	,	login_name
	,	[program_name]
	,	sql_text
	,	sql_command
	,	tran_log_writes
	,	CPU
	,	tempdb_allocations
	,	tempdb_current
	,	reads
	,	writes
	,	physical_reads
	,	query_plan
	,	used_memory
	,	tran_start_time
	,	open_tran_count
	,	percent_complete
	,	additional_info
	,	start_time
	,	login_time
	,	request_id
	FROM
		#resultstemp
	;
END;

GO
