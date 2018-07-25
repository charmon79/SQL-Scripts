USE DBAdmin;
GO

--DROP TABLE IF EXISTS dbo.DatabaseFileSizes;

IF OBJECT_ID('dbo.DatabaseFileSizes') IS NULL
CREATE TABLE dbo.DatabaseFileSizes (
	CollectedTime datetime not null
,	DatabaseID int not null CONSTRAINT FK_DatabaseFileSizes_Databases FOREIGN KEY REFERENCES dbo.Databases (DatabaseID)
,	Type tinyint not null
,	TypeDesc nvarchar(60) NOT NULL
,	FileGroupName sysname null
,	FileName sysname not null
,	PhysicalName nvarchar(260) not null
,	SizeMB numeric(10,2) NOT NULL
,	UsedMB numeric(10,2) NULL -- because FILESTREAM / In-Memory don't report used MB
,	FreeMB AS SizeMB - UsedMB PERSISTED
);

ALTER TABLE dbo.DatabaseFileSizes ADD CONSTRAINT PK_DatabaseFileSizes PRIMARY KEY CLUSTERED (CollectedTime, DatabaseID, Type, FileName);
GO