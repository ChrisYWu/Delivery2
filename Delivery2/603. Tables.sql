USE Merch
GO

----Added 2018-02-22-------------------------
Alter Table Setup.WebAPILog
Add CorrelationID varchar(32)
Go
---------------------------------------------

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

If Not Exists (Select * From sys.tables Where Name = 'DataLoadingLog')
Begin
	CREATE TABLE [ETL].[DataLoadingLog](
		[LogID] [bigint] IDENTITY(1,1) NOT NULL,
		[LogDate]  AS (CONVERT([date],[StartDate])),
		[LastLoadingTimeInSeconds]  AS (datediff(second,[StartDate],[EndDate])),
		[IsMerged]  AS (CONVERT([bit],case when [MergeDate] IS NULL then (0) else (1) end)),
		[TableName] [varchar](100) NOT NULL,
		[SchemaName] [varchar](50) NOT NULL,
		[StartDate] [datetime2](7) NOT NULL,
		[EndDate] [datetime2](7) NULL,
		[NumberOfRecordsLoaded] [int] NULL,
		[LatestLoadedRecordDate] [datetime2](7) NULL,
		[MergeDate] [datetime2](7) NULL,
	 CONSTRAINT [PK_DataLoadingLog] PRIMARY KEY CLUSTERED 
	(
		[StartDate] DESC,
		[SchemaName] ASC,
		[TableName] ASC
	)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
	) ON [PRIMARY]

	Print 'Table ETL.DataLoadingLog created'
End
Go

SET ANSI_PADDING OFF
GO

