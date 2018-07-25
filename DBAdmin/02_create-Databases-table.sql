USE DBAdmin;
GO

IF OBJECT_ID('dbo.Databases') IS NULL
CREATE TABLE dbo.Databases (
	DatabaseName sysname not null
,	Created datetime not null
,	StateDesc nvarchar(60) not null
,	LastSeenOnline datetime null
,	IsReadOnly bit null
,	LastUserAccessTime datetime null
);
GO

ALTER TABLE dbo.Databases ADD CONSTRAINT PK_Databases PRIMARY KEY CLUSTERED (DatabaseName);
GO

