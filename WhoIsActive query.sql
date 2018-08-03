EXEC sp_WhoIsActive
    @get_transaction_info = 1
,   @get_outer_command = 1
,   @get_full_inner_text = 1
,   @get_plans = 1
,   @find_block_leaders = 1
,   @get_additional_info = 2
,   @format_output = 1
,   @output_column_list = '[dd hh:mm:ss.mss][collection_time][session_id][duration][status][blocking_session_id][blocked_session_count][wait_info][database_name][host_name][login_name][program_name][sql_text][sql_command][tran_log_writes][CPU][tempdb_allocations][tempdb_current][reads][writes][physical_reads][query_plan][used_memory][tran_start_time][open_tran_count][percent_complete][additional_info][start_time][login_time][request_id]'
;