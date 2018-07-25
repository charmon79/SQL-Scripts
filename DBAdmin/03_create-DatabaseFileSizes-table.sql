USE DBAdmin;
GO

IF OBJECT_ID('dbo.DatabaseFileSizes') IS NULL
CREATE TABLE dbo.DatabaseFileSizes (
	CollectedTime datetime not null
,	DatabaseName sysname not null
,	Type tinyint not null
,	TypeDesc nvarchar(60) NOT NULL
,	FileGroupName sysname null
,	FileName sysname not null
,	PhysicalName nvarchar(260) not null
,	SizeMB numeric(10,2) NOT NULL
,	UsedMB numeric(10,2) NULL -- because FILESTREAM / In-Memory don't report used MB
,	FreeMB AS SizeMB - UsedMB PERSISTED
);

ALTER TABLE dbo.DatabaseFileSizes ADD CONSTRAINT PK_DatabaseFileSizes PRIMARY KEY CLUSTERED (CollectedTime, DatabaseName, Type, FileName);
GO
