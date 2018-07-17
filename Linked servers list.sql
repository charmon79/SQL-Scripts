SELECT
	server_id
,	name
,	product
,	provider
,	data_source
,	location
,	provider_string
,	catalog
,	is_linked
,	is_remote_login_enabled
,	is_rpc_out_enabled
,	is_data_access_enabled
,	is_collation_compatible
,	uses_remote_collation
,	collation_name
,	is_system
,	is_subscriber
,	is_publisher
,	is_distributor
,	is_nonsql_subscriber
,	is_remote_proc_transaction_promotion_enabled
FROM
	sys.servers
WHERE
	server_id > 0