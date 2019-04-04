SELECT
    serverproperty('MachineName') [Machine Name]
,   serverproperty('InstanceName') [Instance Name]
,   d.name [Database Name]
,   d.state_desc [State]
,   d.compatibility_level [Compatibility Level]
,   d.is_read_only [Read Only]
,   d.is_published [Published]
,   d.is_subscribed [Subscribed]
,   i.LastUserAccessTime [Last Accessed]
,   f.SizeMB [Total Data File MB]
FROM
    sys.databases AS d
    CROSS APPLY (
        SELECT (sum(size) * 8.0) / 1024.0 AS SizeMB
        FROM sys.master_files
        WHERE database_id = d.database_id
        and type <> 1
    ) AS f
	CROSS APPLY (
			SELECT
				MAX(COALESCE(last_user_seek, last_user_scan, last_user_update)) AS LastUserAccessTime
			FROM
				sys.dm_db_index_usage_stats
			WHERE
				database_id = d.database_id
	) AS i
WHERE
    d.database_id > 4
    AND d.name NOT IN ('distribution','DBAdmin')
;