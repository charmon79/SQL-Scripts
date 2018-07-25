USE DBAdmin;
GO

--DROP TABLE IF EXISTS dbo.Databases

IF OBJECT_ID('dbo.Databases') IS NULL
CREATE TABLE dbo.Databases (
	DatabaseID int not null
,	DatabaseName sysname not null
,	Created datetime not null
,	StateDesc nvarchar(60) not null
,	LastSeenOnline datetime not null
,	IsReadOnly bit null
,	LastUserAccessTime datetime null
);
GO

ALTER TABLE dbo.Databases ADD CONSTRAINT PK_Databases PRIMARY KEY CLUSTERED (DatabaseID);
GO
