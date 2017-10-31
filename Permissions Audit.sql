/* Parameters */
DECLARE @sourceDB sysname = 'XcelWeb_Prod'
    
;

/* Script body */
DECLARE @granteeName sysname
    ,   @class INT
    ,   @classDesc NVARCHAR(60)
    ,   @securable NVARCHAR(300)
    ,   @columnName sysname
    ,   @permissionName NVARCHAR(128)
    ,   @permissionState CHAR(1)
    ,   @grantorName sysname
    ,   @sql NVARCHAR(MAX)
;

DROP TABLE IF EXISTS #permissions;
CREATE TABLE #permissions (
    GranteeName sysname
,   class int
,   class_desc NVARCHAR(60)
,   securable NVARCHAR(300) NULL
,   ColumnName sysname NULL
,   PermissionName NVARCHAR(128)
,   PermissionState CHAR(1)
,   GrantorName sysname
)

/* permissions to be re-created in the target database */
SET @sql = N'
USE '+QUOTENAME(@sourceDB)+';
WITH cteSecurables AS (
    SELECT
        1 AS class
    ,   ''OBJECT'' AS class_desc
    ,   o.object_id AS major_id
    ,   QUOTENAME(s.name) + ''.'' + QUOTENAME(o.name) AS securable
    FROM
        sys.schemas AS s
        JOIN sys.objects AS o ON o.schema_id = s.schema_id
    UNION ALL
    SELECT
        3 AS class
    ,   ''SCHEMA'' AS class_desc
    ,   s.schema_id AS major_id
    ,   QUOTENAME(s.name) AS securable
    FROM
        sys.schemas AS s
    UNION ALL
    SELECT
        4 AS class
    ,   ''ROLE'' AS class_desc
    ,   dp.principal_id AS major_id
    ,   QUOTENAME(dp.name) AS securable
    FROM
        sys.database_principals AS dp
    WHERE
        dp.type = ''R''
    UNION ALL
    SELECT
        4 AS class
    ,   ''USER'' AS class_desc
    ,   dp.principal_id AS major_id
    ,   QUOTENAME(dp.name) AS securable
    FROM
        sys.database_principals AS dp
    WHERE
        dp.type IN (''U'',''S'',''G'')
    UNION ALL
    SELECT
        5 AS class
    ,   ''ASSEMBLY'' AS class_desc
    ,   a.assembly_id AS major_id
    ,   QUOTENAME(a.name) AS securable
    FROM
        sys.assemblies AS a
    UNION ALL
    SELECT
        6 AS class
    ,   ''TYPE'' AS class_desc
    ,   t.user_type_id AS major_id
    ,   QUOTENAME(t.name) AS securable
    FROM
        sys.types AS t
    UNION ALL
    SELECT
        10 AS class
    ,   ''XML SCHEMA COLLECTION'' AS class_desc
    ,   xsc.xml_collection_id AS major_id
    ,   QUOTENAME(xsc.name) AS securable
    FROM
        sys.xml_schema_collections AS xsc
    UNION ALL
    SELECT
        15 AS class
    ,   ''MESSAGE TYPE'' AS class_desc
    ,   smt.message_type_id AS major_id
    ,   QUOTENAME(smt.name COLLATE SQL_Latin1_General_CP1_CI_AS) AS securable
    FROM
        sys.service_message_types AS smt
    UNION ALL
    SELECT
        16 AS class
    ,   ''SERVICE CONTRACT'' AS class_desc
    ,   sc.service_contract_id AS major_id
    ,   QUOTENAME(sc.name) AS securable
    FROM
        sys.service_contracts AS sc
    UNION ALL
    SELECT
        17 AS class
    ,   ''SERVICE'' AS class_desc
    ,   s.service_id AS major_id
    ,   QUOTENAME(s.name) AS securable
    FROM
        sys.services AS s
    UNION ALL
    SELECT
        18 AS class
    ,   ''REMOTE SERVICE BINDING'' AS class_desc
    ,   rsb.remote_service_binding_id AS major_id
    ,   QUOTENAME(rsb.name) AS securable
    FROM
        sys.remote_service_bindings AS rsb
    UNION ALL
    SELECT
        19 AS class
    ,   ''ROUTE'' AS class_desc
    ,   r.route_id AS major_id
    ,   QUOTENAME(r.name) AS securable
    FROM
        sys.routes AS r
    UNION ALL
    SELECT
        23 AS class
    ,   ''FULLTEXT CATALOG'' AS class_desc
    ,   fc.fulltext_catalog_id AS major_id
    ,   QUOTENAME(fc.name) AS securable
    FROM
        sys.fulltext_catalogs AS fc
    UNION ALL
    SELECT
        24 AS class
    ,   ''SYMMETRIC KEY'' AS class_desc
    ,   sk.symmetric_key_id AS major_id
    ,   QUOTENAME(sk.name) AS securable
    FROM
        sys.symmetric_keys AS sk
    UNION ALL
    SELECT
        25 AS class
    ,   ''CERTIFICATE'' AS class_desc
    ,   c.certificate_id AS major_id
    ,   QUOTENAME(c.name) AS securable
    FROM
        sys.certificates AS c
    UNION ALL
    SELECT
        26 AS class
    ,   ''ASYMMETRIC KEY'' AS class_desc
    ,   ak.asymmetric_key_id AS major_id
    ,   QUOTENAME(ak.name) AS securable
    FROM
        sys.asymmetric_keys AS ak
)';
SET @sql += N'
SELECT
    users.name AS GranteeName
,   perms.class AS class
,   s.class_desc
,   s.securable
,   c.name AS ColumnName
,   perms.permission_name AS PermissionName
,   perms.state AS PermissionState
,   ISNULL(grantors.name, ''dbo'') AS GrantorName
FROM sys.database_principals AS users
    JOIN sys.database_permissions AS perms ON perms.grantee_principal_id = users.principal_id
    LEFT JOIN sys.database_principals AS grantors ON grantors.principal_id = perms.grantor_principal_id AND grantors.is_fixed_role = 0
    LEFT JOIN cteSecurables AS s
        ON s.class = perms.class AND s.major_id = perms.major_id
    LEFT JOIN sys.columns AS c
        ON c.object_id = perms.major_id AND c.column_id = perms.minor_id
;'

INSERT #permissions
EXEC (@sql);

SELECT DISTINCT
  p.GranteeName AS UserName
, p.class
, p.class_desc
, p.securable
--, p.ColumnName
, ColumnList = STUFF( (SELECT ',' + p2.ColumnName
               FROM #permissions AS p2
               WHERE p2.GranteeName = p.GranteeName
                     AND p2.class = p.class
                     AND p2.securable = p.securable
                     AND p2.ColumnName IS NOT NULL
               ORDER BY p2.ColumnName
               FOR XML PATH(''), TYPE).value('.', 'varchar(max)')
            ,1,1,'')
, p.PermissionName
, p.PermissionState
, p.GrantorName
FROM #permissions AS p
WHERE
p.GranteeName = 'xceligentuser'

SELECT
    m.name AS UserName
,   r.name AS RoleName
FROM
    sys.database_role_members AS rm
    JOIN sys.database_principals AS r ON r.principal_id = rm.role_principal_id
    JOIN sys.database_principals AS m ON m.principal_id = rm.member_principal_id
WHERE
    m.name = 'xceligentuser'