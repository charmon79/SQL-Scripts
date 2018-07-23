/*
	Server principals with high-privilege server roles & permissions
*/

WITH ServerRoleMembers AS (
	SELECT
		rm.member_principal_id
	,	rm.role_principal_id
	,	r.name AS role_name
	FROM
		sys.server_role_members AS rm
		JOIN sys.server_principals AS r ON rm.role_principal_id = r.principal_id
	WHERE
		r.name IN ('sysadmin','securityadmin','dbcreator')
)
,	ServerPermissions AS (
	-- server permissions granted directly
	SELECT
		u.principal_id
	,	p.grantor_principal_id
	,	p.permission_name
	,	p.state_desc
	FROM
		sys.server_permissions AS p
		JOIN sys.server_principals AS u ON u.principal_id = p.grantee_principal_id
	WHERE
		u.type NOT IN ('R','C') -- ignore roles & certificates
		AND p.grantor_principal_id = 1
		AND p.state IN ('G','W')
		AND p.permission_name IN (
				'CONTROL SERVER'
			,	'ALTER ANY LOGIN'
			,	'ALTER ANY DATABASE'
		)

	UNION ALL
	-- server permissions granted via user-defined server role
	SELECT
		u.principal_id
	,	p.grantor_principal_id
	,	p.permission_name
	,	p.state_desc
	FROM
		sys.server_permissions AS p
		JOIN sys.server_principals AS u ON u.principal_id = p.grantee_principal_id
	WHERE
		u.type NOT IN ('R','C') -- ignore roles & certificates
		AND p.grantor_principal_id > 1
		AND p.state IN ('G','W')
		AND p.permission_name IN (
				'CONTROL SERVER'
			,	'ALTER ANY LOGIN'
			,	'ALTER ANY DATABASE'
		)

)
SELECT
	u.name
,	u.type
,	u.type_desc
,	u.is_disabled
FROM
	sys.server_principals AS u
	

/*
	Database principals with high-privilege server roles & permissions
*/

create server role foo;
create server role bar;
grant control server to bar;

alter server role bar add member [ryanrts\charmon]

grant alter any login to foo;

grant alter any database to test

create login test with password='iuahwed(*&AS^DAW*&EROYUGHi'

