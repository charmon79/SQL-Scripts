USE DBAdmin;
GO

IF OBJECT_ID('dbo.DatabaseTableSizes') IS NULL
CREATE TABLE dbo.DatabaseTableSizes
(
	CollectedTime DATETIME NOT NULL
,	DatabaseName sysname NOT NULL
,	SchemaName sysname NOT NULL
,	TableName sysname NOT NULL
,	Rows BIGINT NOT NULL
,	ReservedMB DECIMAL(10,2) NOT NULL
,	DataMB DECIMAL(10,2) NOT NULL
,	IndexMB DECIMAL(10,2) NOT NULL
,	UsedMB DECIMAL(10,2) NOT NULL
,	UnusedMB DECIMAL(10,2) NOT NULL
,	ObjectType NVARCHAR(60) NOT NULL
);

ALTER TABLE dbo.DatabaseTableSizes ADD CONSTRAINT PK_DatabaseTableSizes PRIMARY KEY CLUSTERED (CollectedTime, DatabaseName, SchemaName, TableName);
GO
