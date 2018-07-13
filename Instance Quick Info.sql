select
	@@version AS [@@Version]
,	SERVERPROPERTY('Edition') AS Edition
,	SERVERPROPERTY('ProductVersion') AS ProductVersion
,	SERVERPROPERTY('IsClustered') AS IsClustered
,	SERVERPROPERTY('IsHadrEnabled') AS IsHadrEnabled
,	SERVERPROPERTY('IsIntegratedSecurityOnly') AS IsIntegratedSecurityOnly
