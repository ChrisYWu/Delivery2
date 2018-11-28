Use Merch
Go

Select @@ServerName DBServer
Go

Create Schema Mesh
Go

/****** Object:  Table [ETL].[DataLoadingLog]    Script Date: 6/14/2018 12:33:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [ETL].[DataLoadingLog](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[LogDate]  AS (CONVERT([date],[StartDate])),
	[LastLoadingTimeInSeconds]  AS (datediff(second,[StartDate],[EndDate])),
	[IsMerged]  AS (CONVERT([bit],case when [LocalMergeDate] IS NULL then (0) else (1) end)),
	[TableName] [varchar](100) NOT NULL,
	[SchemaName] [varchar](50) NOT NULL,
	[StartDate] [datetime2](0) NOT NULL,
	[EndDate] [datetime2](0) NULL,
	[NumberOfRecordsLoaded] [int] NULL,
	[LatestLoadedRecordDate] [datetime2](0) NULL,
	[LocalMergeDate] [datetime2](0) NULL,
	[Query] [nvarchar](1000) NULL,
	[ErrorStep] [varchar](50) NULL,
	[ErrorMessage] [varchar](250) NULL,
 CONSTRAINT [PK_DataLoadingLog] PRIMARY KEY CLUSTERED 
(
	[StartDate] DESC,
	[SchemaName] ASC,
	[TableName] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[CustomerInvoice]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[CustomerInvoice](
	[InvoiceID] [int] IDENTITY(1,1) NOT NULL,
	[DeliveryDateUTC] [date] NOT NULL,
	[RMInvoiceID] [bigint] NULL,
	[RMOrderID] [bigint] NULL,
	[SAPBranchID] [int] NULL,
	[SAPAccountNumber] [int] NOT NULL,
	[TotalQuantity] [int] NULL CONSTRAINT [DF_CustomerInvoice_TotalQuantity]  DEFAULT ((0)),
	[LastModifiedUTC] [datetime2](0) NOT NULL,
	[LastModifiedBy] [varchar](50) NOT NULL,
	[LocalInsertTime] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_CustomerInvoice] PRIMARY KEY CLUSTERED 
(
	[InvoiceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[CustomerOrder]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[CustomerOrder](
	[RMOrderID] [bigint] NOT NULL,
	[DeliveryDateUTC] [datetime2](0) NOT NULL,
	[SAPBranchID] [int] NOT NULL,
	[RMOrderStatus] [int] NOT NULL,
	[RouteID] [int] NULL,
	[DNS] [varchar](10) NULL,
	[SAPAccountNumber] [int] NOT NULL,
	[RMLastModified] [datetime2](0) NOT NULL,
	[LocalSyncTime] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_CustomerOrder] PRIMARY KEY CLUSTERED 
(
	[RMOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[DeliveryRoute]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[DeliveryRoute](
	[DeliveryRouteID] [int] IDENTITY(1,1) NOT NULL,
	[PKEY] [bigint] NOT NULL,
	[DeliveryDateUTC] [date] NOT NULL,
	[RouteID] [int] NOT NULL,
	[TotalQuantity] [int] NOT NULL CONSTRAINT [DF_DeliveryRoute_TotalQuantity]  DEFAULT ((0)),
	[PlannedStartTime] [datetime2](0) NOT NULL,
	[IsStarted]  AS (CONVERT([bit],case when [ActualStartTime] IS NULL then (0) else (1) end)),
	[SAPBranchID] [int] NOT NULL,
	[FirstName] [nvarchar](200) NULL,
	[Lastname] [nvarchar](200) NULL,
	[PhoneNumber] [nvarchar](50) NULL,
	[PlannedCompleteTime] [datetime2](0) NOT NULL,
	[PlannedTravelTime] [int] NOT NULL,
	[PlannedServiceTime] [int] NOT NULL,
	[PlannedBreakTime] [int] NOT NULL,
	[PlannedPreRouteTime] [int] NOT NULL,
	[PlannedPostRouteTime] [int] NOT NULL,
	[ActualStartTime] [datetime2](0) NULL,
	[ActualStartGSN] [varchar](50) NULL,
	[ActualStartFirstName] [varchar](50) NULL,
	[ActualStartLastName] [varchar](50) NULL,
	[ActualStartPhoneNumber] [varchar](50) NULL,
	[ActualStartLatitude] [decimal](10, 7) NULL,
	[ActualStartLongitude] [decimal](10, 7) NULL,
	[ActualCompleteTime] [datetime2](0) NULL,
	[LastModifiedBy] [varchar](50) NOT NULL,
	[LastModifiedUTC] [datetime2](0) NOT NULL,
	[LocalSyncTime] [datetime2](0) NOT NULL,
	[OrderCountLastUpdatedLocalTime] [datetime2](0) NULL,
 CONSTRAINT [PK_DeliveryRoute] PRIMARY KEY NONCLUSTERED 
(
	[DeliveryRouteID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[DeliveryStop]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[DeliveryStop](
	[DeliveryStopID] [int] IDENTITY(1,1) NOT NULL,
	[PlannedStopID] [int] NULL,
	[DeliveryDateUTC] [date] NOT NULL,
	[RouteID] [int] NOT NULL,
	[Sequence] [int] NOT NULL,
	[StopType] [varchar](20) NULL,
	[SAPAccountNumber] [varchar](50) NULL,
	[IsAddedByDriver] [bit] NOT NULL CONSTRAINT [DF_DeliveryStop_IsAddedByDriver]  DEFAULT ((0)),
	[Quantity] [int] NULL,
	[PlannedArrival] [datetime2](0) NULL,
	[ServiceTime] [int] NULL,
	[TravelToTime] [int] NULL,
	[Voided] [bit] NOT NULL CONSTRAINT [DF_DeliveryStop_Voided]  DEFAULT ((0)),
	[DNS]  AS (CONVERT([bit],case when [DNSReasonCode] IS NULL then (0) else (1) end)),
	[DNSReasonCode] [varchar](20) NULL,
	[DNSReason] [varchar](200) NULL,
	[EstimatedArrivalTime] [datetime2](0) NULL,
	[CheckInTime] [datetime2](0) NULL,
	[ArrivalTime] [datetime2](0) NULL,
	[CheckInFarAwayReasonID] [int] NULL,
	[CheckInDistance] [decimal](10, 6) NULL,
	[CheckInLatitude] [decimal](10, 6) NULL,
	[CheckInLongitude] [decimal](10, 6) NULL,
	[EstimatedDepartureTime] [datetime2](0) NULL,
	[CheckOutTime] [datetime2](0) NULL,
	[DepartureTime] [datetime2](0) NULL,
	[CheckOutLatitude] [decimal](10, 6) NULL,
	[CheckOutLongitude] [decimal](10, 6) NULL,
	[ActualServiceTime]  AS (CONVERT([int],datediff(second,[ArrivalTime],[DepartureTime]))),
	[LastModifiedBy] [varchar](50) NULL,
	[LastModifiedUTC] [datetime2](0) NULL,
	[LocalUpdateTime] [datetime2](0) NULL,
 CONSTRAINT [PK_DeliveryStop] PRIMARY KEY CLUSTERED 
(
	[DeliveryStopID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[FarAwayReason]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Mesh].[FarAwayReason](
	[FarAwayReasonID] [int] NOT NULL,
	[ReasonDesc] [nvarchar](200) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_FarAwayReason] PRIMARY KEY CLUSTERED 
(
	[FarAwayReasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [Mesh].[InvoiceItem]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[InvoiceItem](
	[InvoiceItemID] [int] IDENTITY(1,1) NOT NULL,
	[RMInvoiceID] [bigint] NULL,
	[ItemNumber] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[LastModifiedUTC] [datetime2](0) NOT NULL,
	[LastModifiedBy] [varchar](50) NOT NULL,
	[LocalInsertTime] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_InvoiceItem] PRIMARY KEY CLUSTERED 
(
	[InvoiceItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[MyDayActivityLog]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[MyDayActivityLog](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[WebEndPoint] [varchar](50) NULL,
	[StoredProc] [varchar](50) NULL,
	[GetParemeters] [varchar](250) NULL,
	[PostJson] [varchar](max) NULL,
	[RequestTime] [datetime2](7) NULL,
	[CorrelationID] [varchar](32) NULL,
	[DeliveryDateUTC] [date] NULL,
	[RouteID] [int] NULL,
	[GSN] [varchar](50) NULL,
 CONSTRAINT [PK_MyDayActivityLog] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[OrderItem]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[OrderItem](
	[OrderItemID] [int] IDENTITY(1,1) NOT NULL,
	[RMOrderID] [bigint] NOT NULL,
	[ItemNumber] [int] NOT NULL,
	[Quantity] [int] NOT NULL,
	[RMLastModified] [datetime2](0) NOT NULL,
	[RMLastModifiedBy] [varchar](50) NOT NULL,
	[LocalSyncTime] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_OrderItem] PRIMARY KEY CLUSTERED 
(
	[OrderItemID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[PlannedStop]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[PlannedStop](
	[PlannedStopID] [int] IDENTITY(1,1) NOT NULL,
	[DeliveryRouteID] [int] NOT NULL,
	[PKEY] [bigint] NULL,
	[DeliveryDateUTC] [date] NOT NULL,
	[RouteID] [int] NOT NULL,
	[Sequence] [int] NOT NULL,
	[StopType] [varchar](20) NOT NULL,
	[SAPAccountNumber] [varchar](50) NULL,
	[Quantity] [int] NOT NULL CONSTRAINT [DF_PlannedStop_Quantity]  DEFAULT ((0)),
	[PlannedArrival] [datetime2](0) NULL,
	[TravelToTime] [int] NULL,
	[ServiceTime] [int] NULL,
	[LastModifiedBy] [varchar](50) NULL,
	[LastModifiedUTC] [datetime2](0) NULL,
	[LocalSyncTime] [datetime2](0) NULL,
	[OrderCountLastUpdatedLocalTime] [datetime2](0) NULL,
 CONSTRAINT [PK_PlannedStop] PRIMARY KEY NONCLUSTERED 
(
	[PlannedStopID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[ResequeceReasons]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Mesh].[ResequeceReasons](
	[ResequenceID] [int] NOT NULL,
	[ResequenceReasonID] [int] NOT NULL,
 CONSTRAINT [PK_ResequeceReasons] PRIMARY KEY CLUSTERED 
(
	[ResequenceID] ASC,
	[ResequenceReasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [Mesh].[Resequence]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[Resequence](
	[ResequenceID] [int] IDENTITY(1,1) NOT NULL,
	[AddtionalReason] [nvarchar](250) NULL,
	[RouteID] [int] NOT NULL,
	[DeliveryDateUTC] [date] NOT NULL,
	[StartSequenceID] [int] NULL,
	[EndSequenceID] [int] NULL,
	[LastModifiedUTC] [datetime2](0) NOT NULL,
	[LastModifiedBy] [varchar](50) NOT NULL,
	[LocalUpdateTime] [datetime2](0) NOT NULL,
 CONSTRAINT [PK_Resequence] PRIMARY KEY CLUSTERED 
(
	[ResequenceID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Mesh].[ResequenceDetail]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Mesh].[ResequenceDetail](
	[ResequenceDetailID] [bigint] IDENTITY(1,1) NOT NULL,
	[ResequenceID] [int] NOT NULL,
	[Sequence] [int] NOT NULL,
	[OldEstimatedArrival] [datetime2](0) NULL,
	[DeliveryStopID] [int] NOT NULL,
	[NewSequence] [int] NOT NULL,
	[NewEstimatedArrival] [datetime2](0) NULL,
 CONSTRAINT [PK_ResequenceBefore] PRIMARY KEY CLUSTERED 
(
	[ResequenceDetailID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [Mesh].[ResequenceReason]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Mesh].[ResequenceReason](
	[ResequenceReasonID] [int] NOT NULL,
	[ReasonDesc] [nvarchar](200) NOT NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_ResequenceReason] PRIMARY KEY CLUSTERED 
(
	[ResequenceReasonID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [Mesh].[StopTypeDesc]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Mesh].[StopTypeDesc](
	[StopType] [varchar](20) NOT NULL,
	[Description] [varchar](50) NOT NULL,
 CONSTRAINT [PK_StopTypeDesc] PRIMARY KEY CLUSTERED 
(
	[StopType] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Staging].[ORDER_DETAIL]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Staging].[ORDER_DETAIL](
	[ORDER_NUMBER] [nvarchar](15) NOT NULL,
	[ITEM_NUMBER] [nvarchar](18) NOT NULL,
	[CASEQTY] [numeric](38, 0) NULL,
	[UPDATE_TIME] [datetime2](0) NOT NULL
) ON [PRIMARY]

GO
/****** Object:  Table [Staging].[ORDER_MASTER]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [Staging].[ORDER_MASTER](
	[ORDER_NUMBER] [nvarchar](15) NOT NULL,
	[CUSTOMER_NUMBER] [nvarchar](10) NULL,
	[LOCATION_ID] [nvarchar](8) NULL,
	[DELIVERYROUTE] [nvarchar](10) NULL,
	[DELIVERYDATE] [datetime2](7) NULL,
	[ORDERSTATUS] [nvarchar](10) NULL,
	[ORDERAMOUNT] [numeric](10, 2) NULL,
	[DNS] [nvarchar](4) NULL,
	[UPDATE_TIME] [datetime2](7) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [Staging].[RS_ROUTE]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Staging].[RS_ROUTE](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[PKEY] [bigint] NULL,
	[RN_SESSION_PKEY] [bigint] NULL,
	[ROUTE_ID] [nvarchar](50) NULL,
	[DRIVER1_ID] [varchar](50) NULL,
	[DRIVER_FNAME] [nvarchar](70) NULL,
	[DRIVER_LNAME] [nvarchar](70) NULL,
	[DRIVER_PHONE_NUM] [nvarchar](40) NULL,
	[LOCATION_REGION_ID_ORIGIN] [nvarchar](50) NULL,
	[STATUS] [varchar](50) NULL,
	[START_TIME] [datetime2](0) NULL,
	[COMPLETE_TIME] [datetime2](0) NULL,
	[DATE_MODIFIED] [datetime2](0) NULL,
	[TRAVEL_TIME] [int] NULL,
	[SERVICE_TIME] [int] NULL,
	[BREAK_TIME] [int] NULL,
	[PREROUTE_TIME] [int] NULL,
	[POSTROUTE_TIME] [int] NULL,
	[USER_MODIFIED] [varchar](50) NULL,
	[Selected] [bit] NULL CONSTRAINT [DF_RS_ROUTE_Selected]  DEFAULT ((0)),
 CONSTRAINT [PK_RS_ROUTE] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [Staging].[RS_STOP]    Script Date: 6/14/2018 12:34:00 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [Staging].[RS_STOP](
	[ROUTE_PKEY] [bigint] NULL,
	[RN_SESSION_PKEY] [bigint] NULL,
	[SALESOFFICE_ID] [varchar](50) NULL,
	[STOP_IX] [int] NULL,
	[SEQUENCE_NUMBER] [int] NULL,
	[STOP_TYPE] [varchar](50) NULL,
	[ACCOUNT_NUMBER] [varchar](50) NULL,
	[ARRIVAL] [datetime2](0) NULL,
	[SERVICE_TIME] [int] NULL,
	[TRAVEL_TIME] [int] NULL,
	[DISTANCE] [int] NULL,
	[USER_MODIFIED] [varchar](50) NULL,
	[DATE_MODIFIED] [datetime2](0) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [Mesh].[DeliveryStop]  WITH CHECK ADD  CONSTRAINT [FK_DeliveryStop_FarAwayReason] FOREIGN KEY([CheckInFarAwayReasonID])
REFERENCES [Mesh].[FarAwayReason] ([FarAwayReasonID])
GO
ALTER TABLE [Mesh].[DeliveryStop] CHECK CONSTRAINT [FK_DeliveryStop_FarAwayReason]
GO
ALTER TABLE [Mesh].[DeliveryStop]  WITH CHECK ADD  CONSTRAINT [FK_DeliveryStop_PlannedStop] FOREIGN KEY([PlannedStopID])
REFERENCES [Mesh].[PlannedStop] ([PlannedStopID])
ON DELETE CASCADE
GO
ALTER TABLE [Mesh].[DeliveryStop] CHECK CONSTRAINT [FK_DeliveryStop_PlannedStop]
GO
ALTER TABLE [Mesh].[OrderItem]  WITH CHECK ADD  CONSTRAINT [FK_OrderItem_CustomerOrder] FOREIGN KEY([RMOrderID])
REFERENCES [Mesh].[CustomerOrder] ([RMOrderID])
ON DELETE CASCADE
GO
ALTER TABLE [Mesh].[OrderItem] CHECK CONSTRAINT [FK_OrderItem_CustomerOrder]
GO
ALTER TABLE [Mesh].[PlannedStop]  WITH CHECK ADD  CONSTRAINT [FK_PlannedStop_DeliveryRoute] FOREIGN KEY([DeliveryRouteID])
REFERENCES [Mesh].[DeliveryRoute] ([DeliveryRouteID])
ON DELETE CASCADE
GO
ALTER TABLE [Mesh].[PlannedStop] CHECK CONSTRAINT [FK_PlannedStop_DeliveryRoute]
GO
ALTER TABLE [Mesh].[PlannedStop]  WITH CHECK ADD  CONSTRAINT [FK_PlannedStop_StopTypeDesc] FOREIGN KEY([StopType])
REFERENCES [Mesh].[StopTypeDesc] ([StopType])
GO
ALTER TABLE [Mesh].[PlannedStop] CHECK CONSTRAINT [FK_PlannedStop_StopTypeDesc]
GO
ALTER TABLE [Mesh].[ResequeceReasons]  WITH CHECK ADD  CONSTRAINT [FK_ResequeceReasons_Resequence] FOREIGN KEY([ResequenceID])
REFERENCES [Mesh].[Resequence] ([ResequenceID])
ON DELETE CASCADE
GO
ALTER TABLE [Mesh].[ResequeceReasons] CHECK CONSTRAINT [FK_ResequeceReasons_Resequence]
GO
ALTER TABLE [Mesh].[ResequeceReasons]  WITH CHECK ADD  CONSTRAINT [FK_ResequeceReasons_ResequenceReason] FOREIGN KEY([ResequenceReasonID])
REFERENCES [Mesh].[ResequenceReason] ([ResequenceReasonID])
GO
ALTER TABLE [Mesh].[ResequeceReasons] CHECK CONSTRAINT [FK_ResequeceReasons_ResequenceReason]
GO
ALTER TABLE [Mesh].[ResequenceDetail]  WITH CHECK ADD  CONSTRAINT [FK_ResequenceDetail_Resequence] FOREIGN KEY([ResequenceID])
REFERENCES [Mesh].[Resequence] ([ResequenceID])
ON DELETE CASCADE
GO
ALTER TABLE [Mesh].[ResequenceDetail] CHECK CONSTRAINT [FK_ResequenceDetail_Resequence]
GO


Insert Into Mesh.ResequenceReason(ResequenceReasonID, ReasonDesc, IsActive)
Values(1, 'Dock Occupied / Long Wait', 1)
Insert Into Mesh.ResequenceReason(ResequenceReasonID, ReasonDesc, IsActive)
Values(2, 'Customer not open at this time',1)
Insert Into Mesh.ResequenceReason(ResequenceReasonID, ReasonDesc, IsActive)
Values(3, 'Missed Receiving Time Window',1)
Insert Into Mesh.ResequenceReason(ResequenceReasonID, ReasonDesc, IsActive)
Values(4, 'Customer Address Incorrect', 1)
Go

Insert Into Mesh.FarAwayReason(FarAwayReasonID, ReasonDesc, IsActive)
Values(1, 'Default Reason', 1)
Go

Alter Table Setup.WebAPILog
Add CorrelationID varchar(32) null
Go

