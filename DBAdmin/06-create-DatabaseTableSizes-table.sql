USE DBAdmin;
GO

IF OBJECT_ID('dbo.DatabaseTableSizes') IS NULL
CREATE TABLE dbo.DatabaseTableSizes
(
	CollectionTime DATETIME NOT NULL
,	DatabaseID INT NOT NULL CONSTRAINT FK_DatabaseTableSizes_Databases FOREIGN KEY REFERENCES dbo.Databases (DatabaseID)
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

ALTER TABLE dbo.DatabaseTableSizes ADD CONSTRAINT PK_DatabaseTableSizes PRIMARY KEY CLUSTERED (CollectionTime, DatabaseID, SchemaName, TableName);
GO
