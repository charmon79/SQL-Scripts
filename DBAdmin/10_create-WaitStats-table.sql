USE [DBAdmin]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF OBJECT_ID('dbo.WaitStats') IS NULL
CREATE TABLE [dbo].[WaitStats](
	[PeriodStart] DATETIME NOT NULL,
	[PeriodEnd] DATETIME NOT NULL,
	[WaitType] [nvarchar](60) NOT NULL,
	[Wait_S] [decimal](16, 2) NOT NULL,
	[Resource_S] [decimal](16, 2) NOT NULL,
	[Signal_S] [decimal](16, 2) NOT NULL,
	[WaitCount] [bigint] NOT NULL,
	[Percentage] [decimal](5, 2) NOT NULL,
	[AvgWait_S] [decimal](16, 4) NOT NULL,
	[AvgRes_S] [decimal](16, 4) NOT NULL,
	[AvgSig_S] [decimal](16, 4) NOT NULL
) ON [PRIMARY]
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE object_id = object_id('dbo.WaitStats') AND index_id = 1)
CREATE CLUSTERED INDEX CIX_WaitStats ON dbo.WaitStats (PeriodStart, [Percentage])
GO
