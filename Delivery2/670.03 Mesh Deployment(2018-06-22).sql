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
	LastManifestFetched [datetime2](0) NULL,
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

Set Nocount On;

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

Print '---$$$ Structure update completed $$$ ---'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/


IF TYPE_ID(N'Mesh.tEstimatedArrivals') IS Not NULL
Begin
	DROP TYPE Mesh.tEstimatedArrivals
	Print '* Mesh.tEstimatedArrivals'
End

GO

CREATE TYPE Mesh.tEstimatedArrivals AS TABLE(
	DeliveryStopID bigint NOT NULL,
	Sequence Int not null,
	EstimatedArrivalTime DateTime2(0) not null,
	PRIMARY KEY CLUSTERED 
(
	DeliveryStopID ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print 'Mesh.tEstimatedArrivals created'
Go

----------------------------------------------------------
----------------------------------------------------------

IF TYPE_ID(N'Mesh.tDNSStops') IS Not NULL
Begin
	DROP TYPE Mesh.tDNSStops
	Print '* Mesh.tDNSStops'
End

GO

CREATE TYPE Mesh.tDNSStops AS TABLE(
	DeliveryStopID bigint NOT NULL,
	DNSReasonCode varchar(20) null,
	DNSReason varchar(200) null,
	PRIMARY KEY CLUSTERED 
(
	DeliveryStopID ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print 'Mesh.tDNSStops created'
Go


------------------------------------------------------------
------------------------------------------------------------
If TYPE_ID(N'Mesh.tInvoiceItems') IS Not NULL
Begin
	Drop Type Mesh.tInvoiceItems
	Print '* Mesh.tInvoiceItems'
End

GO

CREATE TYPE Mesh.tInvoiceItems AS TABLE(
	RMInvoiceID bigint null,
	ItemNumber int NOT NULL,
	Quantity int NOT NULL
)
GO

Print 'Mesh.tInvoiceItems created'
Go


------------------------------------------------------------
------------------------------------------------------------
If TYPE_ID(N'Mesh.tInvoiceHeaders') IS Not NULL
Begin
	Drop Type Mesh.tInvoiceHeaders
	Print '* Mesh.tInvoiceHeaders'
End

GO

CREATE TYPE Mesh.tInvoiceHeaders AS TABLE(
	DeliveryDateUTC date null,
	RMInvoiceID bigint null,
	RMOrderID bigint null,
	SAPBranchID int null,
	SAPAccountNumber int
)
GO

Print 'Mesh.tInvoiceHeaders created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
If Exists (Select * From sys.procedures Where Name = 'pFillDeliveryQuantity')
Begin
	Drop Proc ETL.pFillDeliveryQuantity
	Print '* ETL.pFillDeliveryQuantity'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec ETL.pFillDeliveryQuantity

*/

Create Proc ETL.pFillDeliveryQuantity
As
	-----Update pre-calculated case quantities ------
	-----Might need to remove the RouteID from join clause, because sometimes they are not consistent
	Update ps
	Set Quantity = TotalQuantity, OrderCountLastUpdatedLocalTime = SysDateTime()
	From Mesh.PlannedStop ps
	Join (
		Select co.DeliveryDateUTC, co.RouteID, co.SAPAccountNumber, Sum(Quantity) TotalQuantity
		From Mesh.CustomerOrder co
		Join Mesh.OrderItem i on co.RMOrderID = i.RMOrderID
		And co.DeliveryDateUTC >= Convert(Date, DateAdd(day, -1, GetUTCDate()))
		Group By co.DeliveryDateUTC, co.RouteID, co.SAPAccountNumber
	) co on ps.DeliveryDateUTC = co.DeliveryDateUTC and ps.SAPAccountNumber = co.SAPAccountNumber
	Where Quantity != TotalQuantity
	--) co on ps.DeliveryDateUTC = co.DeliveryDateUTC and ps.RouteID = co.RouteID and ps.SAPAccountNumber = co.SAPAccountNumber
	-- This will introduce some inconsistency

	--- Not join orders and summing, but join delivery and summing to avoid inconsistency
	Update dr
	Set TotalQuantity = ds.TotalQuantity, OrderCountLastUpdatedLocalTime = SysDateTime()
	From Mesh.DeliveryRoute dr
	Join (
		Select dr.DeliveryRouteID, sum(Quantity) TotalQuantity
		From Mesh.DeliveryRoute dr
		Join Mesh.PlannedStop ps on dr.DeliveryRouteID = ps.DeliveryRouteID
		Group By dr.DeliveryRouteID
	) ds on dr.DeliveryRouteID = ds.DeliveryRouteID
	Where dr.TotalQuantity != ds.TotalQuantity

Go

Print 'ETL.pFillDeliveryQuantity created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

If Exists (Select * From sys.procedures Where Name = 'pLoadDeliverySchedulePeriodically')
Begin
	Drop Proc ETL.pLoadDeliverySchedulePeriodically
	Print '* ETL.pLoadDeliverySchedulePeriodically'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc ETL.pLoadDeliverySchedulePeriodically
As
    Set NoCount On;
	Declare @LastLoadTime DateTime
	Declare @MLogID bigint, @SLogID bigint 
	Declare @OPENQUERY nvarchar(4000)
	Declare @RecordCount int
	Declare @LastRecordDate DateTime

	------------------------------------------------------
	------------------------------------------------------
	Truncate Table Staging.RS_STOP

	Select @LastLoadTime = Max(LatestLoadedRecordDate)
	From ETL.DataLoadingLog l
	Where SchemaName = 'Staging' And TableName = 'RS_ROUTE'
	And l.IsMerged = 1

	Set @LastLoadTime = Null

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'RS_STOP', GetDate())

	Select @SLogID = SCOPE_IDENTITY()

	---- STATUS CAN BE 'ACTIVE, BUILT, OR PUBLISHED'
	------------------------------------------------
	Set @OPENQUERY = 'Insert Into Staging.RS_STOP Select * From OpenQuery(' 
	Set @OPENQUERY += 'RN' +  ', ''';
	Set @OPENQUERY += ' SELECT   
					S.ROUTE_PKEY, S.RN_SESSION_PKEY,
					S.LOCATION_REGION_ID SALESOFFICE_ID, 
					S.STOP_IX, 
					S.SEQUENCE_NUMBER, 
					S.STOP_TYPE, S.LOCATION_ID ACCOUNT_NUMBER, 
					S.ARRIVAL, S.SERVICE_TIME, S.TRAVEL_TIME, S.DISTANCE, S.USER_MODIFIED, S.DATE_MODIFIED
					FROM TSDBA.RS_ROUTE R, TSDBA.RS_STOP S 
					WHERE R.STATUS = ''''PUBLISHED'''' '
	If (@LastLoadTime is null)
	Begin
		Set @OPENQUERY += 'AND R.START_TIME >= TO_DATE('''''
		Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'
	End
	Else
	Begin
		Set @OPENQUERY += 'AND R.DATE_MODIFIED > TO_DATE('''''
		Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
	End
	Set @OPENQUERY += ' AND S.RN_SESSION_PKEY = R.RN_SESSION_PKEY      
					AND S.ROUTE_PKEY = R.PKEY '
	Set @OPENQUERY += ''')'	
	--Select @OPENQUERY
	Exec(@OPENQUERY)

	--2
	Select @RecordCount = Count(*) From Staging.RS_STOP
	Select @LastRecordDate = Max(DATE_MODIFIED) From Staging.RS_STOP

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY

	Where LogID = @SLogID

	--*******************************************
	--*******************************************
	Truncate Table Staging.RS_ROUTE

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'RS_ROUTE', GetDate())

	Select @MLogID = SCOPE_IDENTITY()

	---- STATUS CAN BE 'ACTIVE, BUILT, OR PUBLISHED', we take the PUBLISHED ----
	----------------------------------------------------------------------------
	Set @OPENQUERY = 'Insert Into Staging.RS_ROUTE Select *, 0 From OpenQuery(' 
	Set @OPENQUERY += 'RN' +  ', ''';
	Set @OPENQUERY += ' SELECT 
			R.PKEY, R.RN_SESSION_PKEY, R.ROUTE_ID, 
			R.DRIVER1_ID, E.FIRST_NAME DRIVER_FNAME, E.LAST_NAME DRIVER_LNAME, E.WORK_PHONE_NUMBER DRIVER_PHONE_NUM, 
			R.LOCATION_REGION_ID_ORIGIN, 
			R.STATUS, R.START_TIME, R.COMPLETE_TIME, R.DATE_MODIFIED, R.TRAVEL_TIME, R.SERVICE_TIME, R.BREAK_TIME, R.PREROUTE_TIME, R.POSTROUTE_TIME, R.USER_MODIFIED 
		FROM TSDBA.RS_ROUTE R LEFT JOIN TSDBA.TS_EMPLOYEE E ON R.DRIVER1_ID = E.ID 
		WHERE R.STATUS = ''''PUBLISHED'''' '
	If (@LastLoadTime is null)
	Begin
		Set @OPENQUERY += 'AND R.START_TIME >= TO_DATE('''''
		Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'
	End
	Else
	Begin
		Set @OPENQUERY += 'AND R.DATE_MODIFIED > TO_DATE('''''
		Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
	End
	Set @OPENQUERY += ''')'	
	--Select @OPENQUERY
	Exec (@OPENQUERY)

	--1
	Select @RecordCount = Count(*) From Staging.RS_ROUTE
	Select @LastRecordDate = Max(DATE_MODIFIED) From Staging.RS_ROUTE

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY
	Where LogID = @MLogID

	---------------------------------------
	---MERGING-----------------------------
	---------------------------------------

	-- Can't do historical data delete, the route level has transactional data
	--- Determine Pkey 
	Begin Try
	Declare @RoutePkey Table
	(
		ID int
	)

	Insert Into @RoutePkey
	Select Max(ID) ID
	From Staging.RS_Route r
	Join 
	(
		Select  
		Convert(Date, START_TIME) StartDate,
		ROUTE_ID, 
		Max(DATE_MODIFIED) LastUpdateTime
		From Staging.RS_Route
		Group By ROUTE_ID, Convert(Date, START_TIME)
	) s on Convert(Date, r.START_TIME) = StartDate and r.Route_ID = s.Route_ID and s.LastUpdateTime = r.DATE_MODIFIED
	Group By r.ROUTE_ID, Convert(Date, r.START_TIME)

	Update r
	Set Selected = 1
	From @RoutePkey rp
	Join Staging.RS_Route r on rp.ID = r.ID

	--- Delete the route stops is not started and has updates coming in
	Delete ps
	From Mesh.PlannedStop ps 
	Join Mesh.DeliveryRoute a on ps.DeliveryRouteID = a.DeliveryRouteID
	Where a.DeliveryDateUTC >= Convert(Date, GetUTCDate())
	And (IsStarted = 0 And LastManifestFetched is null)

	--- Delete the route is not started and has updates coming in
	Delete dr 
	From Mesh.DeliveryRoute dr
	Where DeliveryDateUTC >= Convert(Date, GetUTCDate())
	And (IsStarted = 0 And LastManifestFetched is null)

	Insert Into Mesh.DeliveryRoute
			(PKEY
			,DeliveryDateUTC
			,RouteID
			,PlannedStartTime
			,SAPBranchID
			,FirstName
			,LastName
			,PhoneNumber
			,PlannedCompleteTime
			,PlannedTravelTime
			,PlannedServiceTime
			,PlannedBreakTime
			,PlannedPreRouteTime
			,PlannedPostRouteTime
			,LastModifiedBy
			,LastModifiedUTC
			,LocalSyncTime)
	Select R.PKEY, 
		Convert(Date, START_TIME),
		Replace(R.ROUTE_ID, '.', ''), 
		START_TIME, 
		Convert(int, Substring(convert(varchar, LOCATION_REGION_ID_ORIGIN), 1, 4)), 
		dbo.udf_TitleCase(DRIVER_FNAME), 
		dbo.udf_TitleCase(DRIVER_LNAME), 
		DRIVER_PHONE_NUM, 
		COMPLETE_TIME, 
		Convert(int, TRAVEL_TIME), 
		convert(int, SERVICE_TIME), 
		Convert(int, BREAK_TIME), 
		convert(int, PREROUTE_TIME), 
		POSTROUTE_TIME, 
		USER_MODIFIED, 
		DATE_MODIFIED,
		GetDate()
	From Staging.RS_Route R
	Left Join Mesh.DeliveryRoute dr on dr.DeliveryDateUTC = Convert(Date, r.START_TIME) and convert(varchar(20), dr.RouteID) = convert(varchar(20), r.Route_ID)
	Where 
	Selected = 1
	And (Isnull(IsStarted, 0) = 0 and LastManifestFetched is null)
	And IsNumeric(Replace(R.ROUTE_ID, '.', '')) = 1

	------------------------------------------
	Insert Into Mesh.PlannedStop(
		DeliveryRouteID, 
		Pkey, 
		DeliveryDateUTC, 
		RouteID, 
		Sequence, 
		StopType, 
		SAPAccountNumber, 
		PlannedArrival, 
		TravelToTime, 
		ServiceTime, 
		LastModifiedBy, 
		LastModifiedUTC, 
		LocalSyncTime
	)
	Select 
	dr.DeliveryRouteID, 
	dr.Pkey,
	dr.DeliveryDateUTC,
	dr.RouteID, 
	s.STOP_IX, 
	s.STOP_TYPE, 
	s.ACCOUNT_NUMBER, 
	s.ARRIVAL, 
	s.TRAVEL_TIME, 
	s.SERVICE_TIME, 
	s.USER_MODIFIED, 
	s.DATE_MODIFIED, 
	GetDate()
	From Staging.RS_Route r
	Join Staging.RS_Stop s on r.Pkey = s.Route_PKey
	Join Mesh.DeliveryRoute dr on dr.DeliveryDateUTC = Convert(Date, r.START_TIME) and convert(varchar(20), dr.RouteID) = convert(varchar(20), r.Route_ID)
	Where Selected = 1
	And (Isnull(IsStarted, 0) = 0 and LastManifestFetched is null)

	----------------------------------------
	
	exec ETL.pFillDeliveryQuantity
	End Try
	Begin Catch
		Declare @ErrorMessage varchar(200)
		Select @ErrorMessage = Error_Message()

		Update ETL.DataLoadingLog 
		Set ErrorMessage = @ErrorMessage
		Where LogID in (@SLogID, @MLogID)	
	End Catch

	Update ETL.DataLoadingLog 
	Set LocalMergeDate = GetDate()
	Where LogID in (@SLogID, @MLogID)

Go

Print 'ETL.pLoadDeliverySchedulePeriodically created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

If Exists (Select * From sys.procedures Where Name = 'pLoadOrderPeriodically')
Begin
	Drop Proc ETL.pLoadOrderPeriodically
	Print '* ETL.pLoadOrderPeriodically'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec ETL.pLoadOrderPeriodically

*/


Create Proc ETL.pLoadOrderPeriodically
As
    Set NoCount On;
	Declare @LastLoadTime DateTime
	Declare @MLogID bigint, @SLogID bigint 
	Declare @OPENQUERY nvarchar(4000)
	Declare @RecordCount int
	Declare @LastRecordDate DateTime
	Declare @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int;

	------------------------------------------------------
	------------------------------------------------------
	Truncate Table Staging.ORDER_DETAIL

	Select @LastLoadTime = Max(LatestLoadedRecordDate)
	From ETL.DataLoadingLog l
	Where SchemaName = 'Staging' And TableName = 'ORDER_MASTER'
	And l.IsMerged = 1

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'ORDER_DETAIL', GetDate())

	Select @SLogID = SCOPE_IDENTITY()

	----=-------------------------------------------
	------------------------------------------------
	Begin Try
		Set @OPENQUERY = 'Insert Into Staging.ORDER_DETAIL Select * From OpenQuery(' 
		Set @OPENQUERY += 'RM' +  ', ''';
		Set @OPENQUERY += 'SELECT OM.ORDER_NUMBER, ITEM_NUMBER, SUM(CASEQTY) CASEQTY, MAX(NVL(OD.UPDATE_TIME, OD.INSERT_TIME)) UPDATE_TIME '
		Set @OPENQUERY += ' FROM ACEUSER.ORDER_MASTER OM, ACEUSER.ORDER_DETAIL OD '
		Set @OPENQUERY += ' WHERE OM.ORDERSTATUS IN (2,3,4) '
		Set @OPENQUERY += ' AND OM.ORDER_NUMBER = OD.ORDER_NUMBER '
		Set @OPENQUERY += ' AND OD.TYPE in ( ''''O'''', ''''F'''' ) '
		If (@LastLoadTime is null)
		Begin
			Set @OPENQUERY += 'AND DELIVERYDATE >= TO_DATE('''''
			Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD '''')'
		End
		Else
		Begin
			Set @OPENQUERY += 'AND OM.UPDATE_TIME > TO_DATE('''''
			Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
		End
		Set @OPENQUERY += ' GROUP BY OM.ORDER_NUMBER, ITEM_NUMBER '	
		Set @OPENQUERY += ''')'	
		Select @OPENQUERY
		Exec (@OPENQUERY)
	End Try
	Begin Catch
		Update ETL.DataLoadingLog 
		Set ErrorMessage = ERROR_MESSAGE(), ErrorStep = 'Load DETAILS from RM'
		Where LogID = @SLogID

		Select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		RaisError (@ErrorMessage, @ErrorSeverity, @ErrorState);
	End Catch


	--2
	Select @RecordCount = Count(*) From Staging.ORDER_DETAIL
	Select @LastRecordDate = Max(UPDATE_TIME) From Staging.ORDER_DETAIL

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY
	Where LogID = @SLogID

	--*******************************************
	--*******************************************
	-- Reuse the @LastLoadTime from the order master table
	Truncate Table Staging.ORDER_MASTER

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'ORDER_MASTER', GetDate())

	Select @MLogID = SCOPE_IDENTITY()

	---------------------------------------------
	Begin Try
		Set @OPENQUERY = 'Insert Into Staging.ORDER_MASTER Select * From OpenQuery(' 
		Set @OPENQUERY += 'RM' +  ', ''';
		Set @OPENQUERY += 'SELECT ORDER_NUMBER, CUSTOMER_NUMBER, LOCATION_ID, DELIVERYROUTE, DELIVERYDATE, ORDERSTATUS, ORDERAMOUNT, DNS, UPDATE_TIME '
		Set @OPENQUERY += ' FROM ACEUSER.ORDER_MASTER '
		Set @OPENQUERY += ' WHERE ORDERSTATUS IN (2,3,4) '
		If (@LastLoadTime is null)
		Begin
			Set @OPENQUERY += 'AND DELIVERYDATE >= TO_DATE('''''
			Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD '''')'
		End
		Else
		Begin
			Set @OPENQUERY += 'AND UPDATE_TIME > TO_DATE('''''
			Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
		End
		Set @OPENQUERY += ''')'	
		Select @OPENQUERY
		Exec (@OPENQUERY)
	End Try
	Begin Catch
		Update ETL.DataLoadingLog 
		Set ErrorMessage = ERROR_MESSAGE(), ErrorStep = 'Load ORDER_MASTER from RM'
		Where LogID in (@MLogID)

		Select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		RaisError (@ErrorMessage, @ErrorSeverity, @ErrorState);
	End Catch
	--1

	Select @RecordCount = Count(*) From Staging.ORDER_MASTER
	Select @LastRecordDate = Max(UPDATE_TIME) From Staging.ORDER_MASTER

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY
	Where LogID = @MLogID

	---------------------------------------
	---MERGING-----------------------------
	---------------------------------------

	-- Historical data delete
	Delete s
	From Mesh.CustomerOrder r  --30 Day history is kept
	Join Mesh.OrderItem s on r.RMOrderID = s.RMOrderID
	Where DateDiff(day, DeliveryDateUTC, GetUTCDate()) > 3

	--- Delete order items that has been updated
	Delete ds
	From Mesh.OrderItem ds
	Join Mesh.CustomerOrder dr on ds.RMOrderID = dr.RMOrderID
	Join Staging.ORDER_MASTER R on dr.RMOrderID = R.ORDER_NUMBER

	--- Delete the order master that has been updated
	Delete dr
	From Mesh.CustomerOrder dr
	Join Staging.ORDER_MASTER R on dr.RMOrderID = R.ORDER_NUMBER

	INSERT INTO Mesh.CustomerOrder
			   (RMOrderID
			   ,DeliveryDateUTC
			   ,SAPBranchID
			   ,RMOrderStatus
			   ,RouteID
			   ,DNS
			   ,SAPAccountNumber 
			   ,RMLastModified
			   ,LocalSyncTime)
	Select ORDER_NUMBER, DELIVERYDATE, substring(Location_ID, 1, 4), ORDERSTATUS, DELIVERYROUTE, DNS, CUSTOMER_NUMBER, UPDATE_TIME 
		,GetDate()
	From Staging.ORDER_MASTER R

	------------------------------------------
	Insert Into Mesh.OrderItem
			   (RMOrderID
			   ,ItemNumber
			   ,Quantity
			   ,RMLastModified
			   ,RMLastModifiedBy
			   ,LocalSyncTime)
	Select ORDER_NUMBER, ITEM_NUMBER, CASEQTY, UPDATE_TIME, 'System', GetDate()
	From Staging.ORDER_DETAIL
	Where ORDER_NUMBER In (Select ORDER_NUMBER From Staging.ORDER_MASTER)
	And CASEQTY > 0

	----------------------------------------
	exec ETL.pFillDeliveryQuantity

	Update ETL.DataLoadingLog 
	Set LocalMergeDate = GetDate()
	Where LogID in (@SLogID, @MLogID)


Go

Print 'ETL.pLoadOrderPeriodically created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

Alter PROCEDURE Setup.pInsertWebAPILog( @ServiceName   VARCHAR(150),
                                            @OperationName VARCHAR(50),
                                            @ModifiedDate  DATETIME,
                                            @GSN           VARCHAR(50)      = NULL,
                                            @Type          VARCHAR(50)      = NULL,
                                            @Exception     VARCHAR(MAX)     = NULL,
                                            @GUID          UNIQUEIDENTIFIER,
                                            @ComputerName  VARCHAR(50)      = NULL,
                                            @UserAgent     VARCHAR(50)      = NULL,
											@Json		   varchar(max)		= Null,
											@CorrelationID varchar(32)      = null
)
AS

BEGIN 
	 INSERT INTO Setup.WebAPILog
         ([ServiceName],
          [OperationName],
          [ModifiedDate],
          [GSN],
          [Type],
          [Exception],
          [GUID],
          [ComputerName],
		  [UserAgent],
		  Json,
		  CorrelationID,
		  ServerInsertTime
         )
         VALUES
         (@ServiceName,
          @OperationName,
          @ModifiedDate,
          @GSN,
          @Type,
          @Exception,
          @GUID,
          @ComputerName,
		  @UserAgent,
		  @Json,
		  @CorrelationID,
		  SysDateTime()
         );


END

Go

Print 'Setup.pInsertWebAPILog updated'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*/

ALTER Proc [Operation].[pGetMerchStoreDelivery]
(
	@DeliveryDate Datetime,
	@SAPAccountNumber varchar(max),
	@IsDetailNeeded bit,
	@Debug bit = 0
)
AS
Begin
	Set NoCount On;

	If (@Debug = 1)
	Begin
		DECLARE @StartTime DateTime2(7)
		Set @StartTime = SYSDATETIME()
		Select '---- Starting ----' Debug, @StartTime StartTime 
	End

	-----------------------------------------------------
	Declare @DeliveryAccount Table
	(
		SAPAccountNumber Int,
		IsMeshDelivery Bit Default 0
	)

	Insert Into @DeliveryAccount(SAPAccountNumber, IsMeshDelivery)
	Select value, 0 From Setup.UDFSplit(@SAPAccountNumber, ',')

	Declare @Value varchar(max)

	Select @Value = Value
	From Setup.Config
	Where [Key] = 'MeshEnabledBranches'

	Update da
	Set IsMeshDelivery = 1
	From dbo.udfSplit(@Value, ',') b
	Join SAP.Branch br on b.Value = br.SAPBranchID
	Join SAP.Account a on br.BranchID = a.BranchID
	Join @DeliveryAccount da on a.SAPAccountNumber = da.SAPAccountNumber	
	Where a.Active = 1

	If (@Debug = 1)
	Begin
		Select '---- Populating @DeliveryAccount----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select * From @DeliveryAccount Order By SAPAccountNumber
	End

	-----------------------------------------------------
	
	Declare @TempStoreDelivery Table
	(
		DeliveryDate Datetime,
		ItemDeliveryDate DateTime,
		SAPAccountNumber bigint,
		ItemSAPAccountNumber bigint,
		PlannedArrival datetime,
		ActualArrival datetime,
		EstimatedArrival datetime Null,
		DriverID nvarchar(50),
		DriverFirstName nvarchar(50),
		DriverLastName nvarchar(50),
		DriverPhone Varchar(50),
		SAPMaterialID Varchar(20),
		Quantity int,	
		Delivered bit
	)

	--Non-mesh -------------------------------------------------------------
	Insert @TempStoreDelivery(DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, 
								SAPMaterialID, Quantity, Delivered)

	Select DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone,
		 SAPMaterialID, Quantity, Delivered
	From
	 ( 
	    Select Distinct sd.DeliveryDate, ditem.DeliveryDate as ItemDeliveryDate,  sd.SAPAccountNumber, dItem.SAPAccountNumber as ItemSAPAccountNumber, sd.PlannedArrival, 
		sd.ActualArrival, sd.DriverID, sd.DriverFirstName, sd.DriverLastName, sd.DriverPhone, dItem.SAPMaterialID, dItem.Description, dItem.Quantity, dItem.Delivered, isnull(sd.InvoiceDelivered, 0) InvoiceDelivered 
		From Operation.StoreDelivery sd
		LEFT OUTER JOIN Operation.DeliveryItem dItem
		ON sd.DeliveryDate = dItem.DeliveryDate and sd.SAPAccountNumber = dItem.SAPAccountNumber
		WHERE sd.DeliveryDate = @DeliveryDate			  
		AND sd.SAPAccountNumber in  (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 0)	
			UNION
		Select sd.DeliveryDate, ditem.DeliveryDate as ItemDeliveryDate, sd.SAPAccountNumber, dItem.SAPAccountNumber as ItemSAPAccountNumber, sd.PlannedArrival,
		 sd.ActualArrival, sd.DriverID, sd.DriverFirstName, sd.DriverLastName, sd.DriverPhone, dItem.SAPMaterialID, dItem.Description, dItem.Quantity, dItem.Delivered, isnull(sd.InvoiceDelivered, 0) InvoiceDelivered
		From Operation.StoreDelivery sd
		RIGHT OUTER JOIN Operation.DeliveryItem dItem
		ON dItem.DeliveryDate = sd.DeliveryDate and dItem.SAPAccountNumber = sd.SAPAccountNumber
		WHERE dItem.DeliveryDate = @DeliveryDate
			AND dItem.SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 0)
	 ) 	input
	Where InvoiceDelivered = Delivered
	If (@Debug = 1)
	Begin
		Select '---- Populating @TempStoreDelivery For NON Mesh Delivery----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select Count(*) TotalCnt From @TempStoreDelivery
	End

	---------------------------------------------------------
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$--
	Declare @T Table
	(
		DeliveryDateUTC Date,
		SAPAccountNumber Int,
		ItemNumber Int,
		Quantity int,
		InvoiceQuantity Int Null
	)


	Insert Into @T(DeliveryDateUTC, SAPAccountNumber, ItemNumber, Quantity)
		Select DeliveryDateUTC, SAPAccountNumber, ItemNumber, Quantity
		From Mesh.CustomerOrder co
		Join Mesh.OrderItem oi on co.RMOrderID = oi.RMOrderID
		Where SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 1)	
		And co.DeliveryDateUTC = @DeliveryDate
	
	Merge @T As T
	Using (
		Select DeliveryDateUTC, SAPAccountNumber, ItemNumber, Quantity
		From Mesh.CustomerInvoice ci
		Join Mesh.InvoiceItem ii on ci.RMInvoiceID = ii.RMInvoiceID
		Where SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 1)	
		And ci.DeliveryDateUTC = @DeliveryDate
	) iv 
	on t.DeliveryDateUTC = iv.DeliveryDateUTC And t.SAPAccountNumber = iv.SAPAccountNumber And t.ItemNumber = iv.ItemNumber
	When Matched Then 
		Update Set T.InvoiceQuantity = iv.Quantity
	When Not Matched By Target Then
	Insert (DeliveryDateUTC, SAPAccountNumber, ItemNumber, Quantity, InvoiceQuantity)
	Values (iv.DeliveryDateUTC, iv.SAPAccountNumber, iv.ItemNumber, iv.Quantity, iv.Quantity);
	---------------------------------------------------------
	If (@Debug = 1)
	Begin
		Select '---- Populating @T The Mesh Delivery, dumping items ----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		--Select * From @T
		Select DeliveryDateUTC, SAPAccountNumber, Count(*) ItemCount From @T Group By DeliveryDateUTC, SAPAccountNumber Order by SAPAccountNumber

		Select '---- Accounts Got Invoices Delivered ----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select Distinct SAPAccountNumber
		From Mesh.CustomerInvoice ci
		Join Mesh.InvoiceItem ii on ci.RMInvoiceID = ii.RMInvoiceID
		Where DeliveryDAteUTC = @DeliveryDate

	End
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$--


	-- Mesh -------------------------------------------------------------
	Insert @TempStoreDelivery(DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, 
								SAPMaterialID, Quantity, Delivered)
	Select DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone,
			SAPMaterialID, Quantity, Delivered
	From
	( 
		Select CONVERT(Varchar(10), dr.DeliveryDateUTC, 126) DeliveryDate, co.DeliveryDateUTC ItemDeliveryDAte, 
			Coalesce(ps.SAPAccountNumber, ds.SAPAccountNumber) SAPAccountNumber, 
			co.SAPAccountNumber ItemSAPAccountNumber, 
			Coalesce(ps.PlannedArrival, ds.PlannedArrival) PlannedArrival, 
			ds.ArrivalTime ActualArrival, 
			ds.EstimatedArrivalTime EstimatedArrival,
			dr.ActualStartGSN DriverID, 
			Coalesce(dr.FirstName, dr.ActualStartFirstName) DriverFirstName, 
			Coalesce(dr.LastName, dr.ActualStartLastName) DriverLastName, 
			Coalesce(dr.PhoneNumber, dr.ActualStartPhoneNumber) DriverPhone, 
			co.ItemNumber SAPMaterialID, co.Quantity, Case When co.InvoiceQuantity is null Then 0 Else 1 End As Delivered 
		From Mesh.DeliveryRoute dr
		Join Mesh.PlannedStop ps on dr.DeliveryRouteID = ps.DeliveryRouteID
		Join @T co on ps.SAPAccountNumber = co.SAPAccountNumber And co.DeliveryDateUTC = ps.DeliveryDateUTC
		Left Join Mesh.DeliveryStop ds on dr.DeliveryDateUTC = ds.DeliveryDateUTC And dr.RouteID = ds.RouteID And ps.PlannedStopID = ds.PlannedStopID
		Where dr.DeliveryDateUTC = @DeliveryDate
		And (ds.Sequence is null or ds.Sequence > 0)
	) 	input

	If (@Debug = 1)
	Begin
		Select '---- Populating @TempStoreDelivery For MESH Delivery done.---' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select Count(*) TotalCnt From @TempStoreDelivery

		Select '---- Dumping @TempStoreDelivery.---' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select *
		From @TempStoreDelivery
	End

	Select Distinct 
		(Case When (DeliveryDate Is Null) Then CONVERT(Varchar(10), ItemDeliveryDate, 126)  Else CONVERT(Varchar(10), DeliveryDate, 126)  End) DeliveryDate,	
		(Case When (SAPAccountNumber Is Null) Then ItemSAPAccountNumber Else SAPAccountNumber End) SAPAccountNumber
		,PlannedArrival, ActualArrival, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone 
	From @TempStoreDelivery	
	Where Quantity > 0

	IF (@IsDetailNeeded = 1)
	BEGIN
		Select tsd.ItemSAPAccountNumber AS SAPAccountNumber, tsd.SAPMaterialID, tsd.Quantity, tsd.Delivered
		From @TempStoreDelivery tsd 
		Where tsd.ItemDeliveryDate Is not Null
		And Quantity > 0
	END
	
	If (@Debug = 1)
	Begin
		Select '---- Select from @TempStoreDelivery done----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
	End

End
Go

Print 'Operation.pGetMerchStoreDelivery updated'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
ALTER Proc Operation.pGetMerchandisingDetails
(
	@OperationDate Datetime,
	@SAPAccountNumber varchar(max)
)
AS
Begin
	Set NoCount On;

	Select 
	--GSNStoreSequence, 
	Convert(int, Row_Number() Over (Partition By SAPAccountNumber Order By IsNull(CheckInTime, '2199-12-31'))) SameStoreCheckInSequence, 
	merc.GSN, 
	SAPAccountNumber, 
	p.FirstName, 
	p.LastName, 
	m.Phone, 
	CheckInTime, 
	CheckOutTime
	From 
	(
		Select COALESCE(actual.GSNStoreSequence, pln.GSNStoreSequence) GSNStoreSequence, 
		COALESCE(actual.GSN, pln.GSN) GSN,
		COALESCE(actual.SAPAccountNumber, pln.SAPAccountNumber) SAPAccountNumber, 
		actual.CheckInTime, actual.CheckOutTime
		From 
		(
			Select Row_Number() Over (Partition By GSN, SAPAccountNumber Order By Sequence) GSNStoreSequence, GSN, SAPAccountNumber
			From Planning.Dispatch
			Where SAPAccountNumber in (Select LTRIM(rtrim(value)) From Setup.UDFSplit(@SAPAccountNumber, ','))
			And InvalidatedBatchID is null
			And DispatchDate = @OperationDate
		) pln
		Full Outer Join 
		(
			Select Row_Number() Over (Partition By inn.GSN, SAPAccountNumber Order By ClientCheckInTime) GSNStoreSequence, inn.GSN, 
			SAPAccountNumber,
			Convert(DateTime2(0), DateAdd(hour, 1*IsNull(tc.OffsetToUTC, 0), inn.ClientCheckInTime)) CheckInTime, 
			Convert(DateTime2(0), DateAdd(hour, 1*IsNull(tco.OffsetToUTC, 0), ot.ClientCheckOutTime)) CheckOutTime
			From Operation.MerchStopCheckIn inn
			Left Join Setup.TimeConversion tc on inn.ClientCheckInTimeZone = tc.TimeZone
			Left Join Operation.MerchStopCheckOut ot on ot.MerchStopID = inn.MerchStopID
			Left Join Setup.TimeConversion tco on ot.ClientCheckOutTimeZone = tco.TimeZone
			Where DispatchDate = @OperationDate
			And SAPAccountNumber in (Select LTRIM(rtrim(value)) From Setup.UDFSplit(@SAPAccountNumber, ','))
		) actual on pln.GSNStoreSequence = actual.GSNStoreSequence And pln.GSN = actual.GSN And pln.SAPAccountNumber = actual.SAPAccountNumber
	) merc
	Left Join Setup.Person p on merc.GSN = p.GSN
	Left Join Setup.Merchandiser m on p.GSN = m.GSN
	Order By SAPAccountNumber
End
Go

Print 'Operation.pGetMerchandisingDetails updated'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*/

ALTER Proc [Planning].[pGetPreDispatch]
(
	@MerchGroupID int,
	@DispatchDate date = null,
	@GSN varchar(50),
	@TimeZoneOffsetToUTC int = 0,
	@Reset bit = 0,
	@Debug bit = 0
)
As
Begin
	If (@Debug = 1)
	Begin
		DECLARE @StartTime DateTime2(7)
		Set @StartTime = SYSDATETIME()
		Select '---- Starting ----' Debug, @StartTime StartTime 
	End

	If @DispatchDate Is Null
	Begin
		Set @DispatchDate = Convert(Date, GetDate())
	End

	Declare @NumberOfChangeSet int
	Select @NumberOfChangeSet = Count(*)
	From (
		Select LastModified
		From Planning.PreDispatch d
		Where MerchGroupID = @MerchGroupID
		And DispatchDate = @DispatchDate
		Group By LastModified
	) temp

	Declare @NumberOfDeploySet int
	Select @NumberOfDeploySet = Count(*)
	From (
		Select ReleaseTime
		From Planning.DispatchBatch d
		Where MerchGroupID = @MerchGroupID
		And DispatchDate = @DispatchDate
	) temp

	Declare @ModifiedTimeStamp DateTime2(7)

	-- Reset Requested
	If (@Reset = 1)
	Begin
		Delete 
		From Planning.PreDispatch
		Where MerchGroupID = @MerchGroupID 
		And DispatchDate = @DispatchDate
		And RouteID <> -1

		Set @ModifiedTimeStamp = SYSUTCDATETIME()

		Insert Into Planning.PreDispatch(DispatchDate, MerchGroupID, SAPAccountNumber, Sequence, GSN, RouteID, LastModified, LastModifiedBy)
		Select @DispatchDate DispatchDate, rsw.MerchGroupID, rsw.SAPAccountNumber, rsw.Sequence, GSN, rsw.RouteID, @ModifiedTimeStamp, @GSN
		From Planning.RouteMerchandiser rm 
		Join Planning.RouteStoreWeekday rsw on rm.RouteID = rsw.RouteID and rm.DayOfWeek = rsw.DayOfWeek
		Where DatePart(dw, @DispatchDate) = rm.DayOfWeek
		And @MerchGroupID = MerchGroupID
		
		Update d
		Set d.SameStoreSequence = t.SameStoreSequence
		From Planning.PreDispatch d
		Join (
			Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
			From Planning.PreDispatch
			Where MerchGroupID = @MerchGroupID And DispatchDate = @DispatchDate
		) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID
	End

	-- @NumberOfChangeSet = 1. In Preview and never released, keep updating from planning for preview untill change set increases or deployset increates
	-- @NumberOfChangeSet = 0. Never loaded, keep updating from planning for preview untill change set increases or deployset increates
	If ((@NumberOfChangeSet < 2) And (@NumberOfDeploySet = 0))
	Begin
		Delete 
		From Planning.PreDispatch
		Where MerchGroupID = @MerchGroupID 
		And DispatchDate = @DispatchDate

		Set @ModifiedTimeStamp = SYSUTCDATETIME()

		Insert Into Planning.PreDispatch(DispatchDate, MerchGroupID, SAPAccountNumber, Sequence, GSN, RouteID, LastModified, LastModifiedBy)
		Select @DispatchDate DispatchDate, rsw.MerchGroupID, rsw.SAPAccountNumber, rsw.Sequence, GSN, rsw.RouteID, @ModifiedTimeStamp, @GSN
		From Planning.RouteMerchandiser rm 
		Join Planning.RouteStoreWeekday rsw on rm.RouteID = rsw.RouteID and rm.DayOfWeek = rsw.DayOfWeek
		Where DatePart(dw, @DispatchDate) = rm.DayOfWeek
		And @MerchGroupID = MerchGroupID
		Union 
		Select @DispatchDate DispatchDate, @MerchGroupID, '-1', -1, 'FirstLoadPlaceHolder', -1, @ModifiedTimeStamp, @GSN
		
		Update d
		Set d.SameStoreSequence = t.SameStoreSequence
		From Planning.PreDispatch d
		Join (
			Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
			From Planning.PreDispatch
			Where MerchGroupID = @MerchGroupID And DispatchDate = @DispatchDate
		) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID

	End

	--Just Reset and never been released ===  updated and reset later while never released, 
	--Sync the time stamp and have it follow the plan if no future modification is made
	If (@Reset= 1 And @NumberOfDeploySet = 0 And @ModifiedTimeStamp is not null)
	Begin
		Update Planning.PreDispatch
		Set LastModified = @ModifiedTimeStamp
		Where MerchGroupID = @MerchGroupID
		And DispatchDate = @DispatchDate
	End

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	Declare @StoreDelivery Table
	(
		DispatchDate Date,
		SAPAccountNumber int,
		IsMesh bit,
		PlannedArrival DateTime,
		EstimatedArrival DateTime,
		ActualArrival DateTime,
		ActualDeparture DateTime
	)

	Declare @Value varchar(max)

	Select @Value = Value
	From Setup.Config
	Where [Key] = 'MeshEnabledBranches'

	If Exists (Select * From Setup.MerchGroup 
				Where MerchGroupID = @MerchGroupID 
				And SAPBranchID in (Select Value From dbo.udfSplit(@Value, ','))
			)
	Begin
		Insert Into @StoreDelivery
		Select pd.DispatchDate, pd.SAPAccountNumber, 1, PlannedArrival, Null As EstimatedArrivalTime, Null As ArrivalTime, Null ActualDeparture
		From Planning.PreDispatch pd
		Join Mesh.PlannedStop ds on pd.DispatchDate = ds.DeliveryDateUTC and pd.SAPAccountNumber = ds.SAPAccountNumber
		Where DispatchDate = @DispatchDate
		And @MerchGroupID = MerchGroupID

		Update s
		Set EstimatedArrival = EstimatedArrivalTime, ActualArrival = ArrivalTime, ActualDeparture = DepartureTime
		From @StoreDelivery s
		Join Mesh.DeliveryStop ds on s.DispatchDate = ds.DeliveryDateUTC and s.SAPAccountNumber = ds.SAPAccountNumber
	End
	Else
	Begin
		Insert Into @StoreDelivery
		Select pd.DispatchDate, pd.SAPAccountNumber, 0, PlannedArrival, Null EstimatedArrival, Null ActualArrival, ActualArrival ActualDeparture
		From Planning.PreDispatch pd
		Join Operation.StoreDelivery ds on pd.DispatchDate = ds.DeliveryDate and pd.SAPAccountNumber = ds.SAPAccountNumber
		Where DispatchDate = @DispatchDate
		And @MerchGroupID = MerchGroupID
	End

	If (@Debug = 1)
	Begin
		Select '---- Dumping @StoreDelivery for MeshEnabledBranches----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		

		Select * From @StoreDelivery
	End
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			
	Select * into #DipatchTable from 
	(
	Select pd.DispatchDate, pd.MerchGroupID, pd.SAPAccountNumber, a.AccountName + ' (' + convert(varchar, a.SAPAccountNumber) + ')' AccountName, pd.RouteID, r.RouteName, pd.Sequence, pd.GSN, IsNull(p.FirstName, '+ Add') FirstName, IsNull(p.LastName, 'Merchandiser') LastName, pd.LastModified, pd.LastModifiedBy, IsNull(ab.AbsoluteURL, '') AbsoluteURL
	, (CASE WHEN d.StoreVisitStatusID = 3 THEN 'GREEN' WHEN d.StoreVisitStatusID = 2 THEN 'GRAY' ELSE '' END) as CheckInGSN
	, (CASE 
			WHEN ISNULL(sd.ActualDeparture, '') != '' 
				THEN  Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.ActualDeparture),100),7)), '') + ' ' +  ' DELIVERED'
			WHEN ISNULL(sd.ActualArrival, '') != '' 
				THEN  Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.ActualArrival),100),7)), '') + ' ' +  ' ARRIVED'
			WHEN ISNULL(sd.EstimatedArrival, '') != '' 
				THEN  Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.EstimatedArrival),100),7)), '') + ' ' +  ' ETA'
			WHEN ISNULL(sd.PlannedArrival, '') != '' 
				THEN Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.PlannedArrival),100),7)), '') + ' ' +  ' SCHEDULE'
		   ELSE 'NO  DELIVERY'
	  END) ActualArrival
	   
	From Planning.PreDispatch pd
	Join SAP.Account a on pd.SAPAccountNumber = a.SAPAccountNumber
	Join Planning.Route r on pd.RouteID = r.RouteID
	Left Join Setup.Person p on pd.GSN = p.GSN
	Left Join Setup.ProfileImage pimage on pimage.GSN = p.GSN
	LEFT JOIN Operation.AzureBlobStorage ab on ab.BlobID = pimage.ImageBlobID
	LEFT JOIN Planning.Dispatch d on d.RouteID = pd.RouteID and d.DispatchDate = pd.DispatchDate and d.GSN = pd.GSN and d.SAPAccountNumber = pd.SAPAccountNumber 
	and d.Sequence = pd.Sequence and d.InValidatedBatchID is NULL
	LEFT JOIN @StoreDelivery sd on sd.SAPAccountNumber = pd.SAPAccountNumber and sd.DispatchDate = pd.DispatchDate
	Where @DispatchDate = pd.DispatchDate
	And pd.MerchGroupID = @MerchGroupID
	
	Union
	Select @DispatchDate, @MerchGroupID, '' SAPAccountNumber, '' AccountName, RouteID, RouteName, -1 Sequence, '' GSN, '+ Add' FirstName, 'Merchandiser' LastName, GetDate() LastModified, null LastModifiedBy,  '' AbsoluteURL
	 ,'' CheckInGSN, '' ActualArrival
	From Planning.Route
	Where MerchGroupID = @MerchGroupID
	And RouteID Not In (
		Select Distinct RouteID
		From Planning.PreDispatch
		Where DispatchDate = @DispatchDate --@DispatchDate
		And MerchGroupID = @MerchGroupID--@MerchGroupID
	)
	)T
	Order by RouteID, Sequence

	---Get the count of promotions that needs to be displayed by sapaccountnumber
	select b.SAPAccountNumber,Count(distinct PromotionID) as DisplayTaskCount into #DisplayCount 
	from [Operation].[DisplayBuild] b
	INNER JOIN #DipatchTable d ON b.SAPAccountNumber = d.SAPAccountNumber
	where @DispatchDate>=ProposedStartDate and  @DispatchDate<=ProposedEndDate and BuildDate is null	
	and b.RequiresDisplay = 1 and b.PromotionExecutionStatusID = 2
	group by b.SAPAccountNumber

	Select t.*,isNULL(d.DisplayTaskCount,0) as DisplayTaskCount 
	from #DipatchTable t
	Left JOIN #DisplayCount d ON t.SAPAccountNumber = d.SAPAccountNumber
	Order by t.RouteID, t.Sequence
	
	-- Last Scheduled Date
	SELECT isnull(Count([ReleaseTime]),0) as ScheduleDateCount	
	FROM [Planning].[DispatchBatch] d
	Inner Join [Setup].[Person] p On p.GSN = d.ReleaedBy
	Where merchgroupid = @MerchGroupID and dispatchdate=@DispatchDate
End
Go

Print 'Planning.pGetPreDispatch updated'
Go


-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

Create Proc Mesh.pUpdateEstimatedArrivals
(
	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(50),
	@LastModifiedUTC DateTime2(0)
)
As
	Set NoCount On;

	Declare @DateString varchar(20)
	Declare @IsStarted Bit
	Declare @DeliveryDateUTC Date
	Declare @RouteID Int
	Declare @TotalRouteAffected Table
	(
		DeliveryDateUTC Date,
		RouteID int
	)

	Insert Into @TotalRouteAffected 
	Select DeliveryDateUTC, RouteID
	From @Estimates e
	Join Mesh.DeliveryStop ds on e.DeliveryStopID = ds.DeliveryStopID
	Group By DeliveryDateUTC, RouteID
	

	If (Select Count(*) From @TotalRouteAffected) > 1
	Begin
	Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

		RAISERROR (N'[ClientDataError]{Mesh.pUpdateEstimatedArrivals}: More than one Route/Date combination found in the updated estimates' , -- Message text.  
			16, -- Severity,  
			1 -- State
			);
	End

	Else If (Select Count(*) From @TotalRouteAffected) = 0
	Begin
	Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

		RAISERROR (N'[ClientDataError]{Mesh.pUpdateEstimatedArrivals}: No Route/Date combination found in the updated estimates' , -- Message text.  
			16, -- Severity,  
			1 -- State
			);
	End

	Else 
	Begin
		Select @IsStarted = IsStarted, @DeliveryDateUTC = dr.DeliveryDateUTC, @RouteID = dr.RouteID
		From @Estimates e
		Join Mesh.DeliveryStop ds on e.DeliveryStopID = ds.DeliveryStopID
		Join Mesh.DeliveryRoute dr on ds.DeliveryDateUTC = dr.DeliveryDateUTC and ds.RouteID = dr.RouteID
		Group By dr.DeliveryDateUTC, dr.RouteID, IsStarted

		If @IsStarted = 0
		Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

			RAISERROR (N'[ClientDataError]{Mesh.pUpdateEstimatedArrivals}: The route has not been checked out. @RouteID=%i and @DeliveryDateUTC=%s.' , -- Message text.  
				16, -- Severity,  
				1, -- State,  
				@RouteID, -- First argument.  
				@DateString); -- Second argument.  
		End
		Else 
		Begin
			Merge Mesh.DeliveryStop t
			Using (Select DeliveryStopID, Sequence, EstimatedArrivalTime
					From @Estimates
			) as S
			On t.DeliveryStopID = s.DeliveryStopID
			When Matched 
			Then Update Set t.Sequence = s.Sequence
							,t.EstimatedArrivalTime = s.EstimatedArrivalTime
							,EstimatedDepartureTime = DateAdd(second, IsNull(ServiceTime, 0), s.EstimatedArrivalTime)
							,t.LastModifiedBy = @LastModifiedBy
							,t.LastModifiedUTC = @LastModifiedUTC
							,t.LocalUpdateTime = SysDateTime();
		End
	End

GO

Print 'Mesh.pUpdateEstimatedArrivals created'
Go
-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*/

Create Proc Mesh.pCancelStopDNS
(
	@DeliveryStopID int,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------	
	If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pCancelStopDNS}: Stop requested for cancel DNS not found @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And StopType = 'STP'))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pCancelStopDNS}: Stop requested for cancel DNS is not of type "STP" @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And DNS = 0))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pCancelStopDNS}: Stop requested for cancel DNS is not DNSed to cancel @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else 
	Begin
		Update ds Set
		ds.DNSReasonCode = null
		,ds.DNSReason = null
		,ds.LastModifiedBy = @LastModifiedBy
		,ds.LastModifiedUTC = @LastModifiedUTC
		,ds.LocalUpdateTime = SysDateTime()
		From Mesh.DeliveryStop ds
		Where ds.DeliveryStopID = @DeliveryStopID

	End

GO

Print 'Mesh.pCancelStopDNS created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Proc Mesh.pCheckInDeliveryStop
(
	@CurrentDeliveryStopID int,
	@CheckInTime DateTime2(0),
	@ArrivalTime DateTime2(0) = null,
	@CheckInFarAwayReasonID int = null,
	@CheckInDistance Decimal(10,6) = 0.0,
	@CheckInLatitude Decimal(10,6) = 0.0,
	@CheckInLongitude Decimal(10,6) = 0.0,
	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(50),
	@LastModifiedUTC DateTime2(0)
)
As
	Set NoCount On;

	If @ArrivalTime Is Null
		Set @ArrivalTime = @CheckInTime

	Update Mesh.DeliveryStop
	Set	
		CheckInTime = @CheckInTime
		,ArrivalTime = @ArrivalTime
		,CheckInFarawayReasonID = @CheckInFarAwayReasonID
		,CheckInDistance = @CheckInDistance 
		,CheckInLatitude = @CheckInLatitude
		,CheckInLongitude = @CheckInLongitude
		,EstimatedDepartureTime = DateAdd(second, IsNull(ServiceTime, 0), @CheckInTime)
		,LastModifiedBy = @LastModifiedBy
		,LastModifiedUTC = @LastModifiedUTC
		,LocalUpdateTime = SysDateTime()
	Where DeliveryStopID = @CurrentDeliveryStopID
	And DNS = 0

	exec Mesh.pUpdateEstimatedArrivals @Estimates = @Estimates, @LastModifiedBy = @LastModifiedBy, @LastModifiedUTC = @LastModifiedUTC	
GO

Print 'Mesh.pCheckInDeliveryStop created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Proc [Mesh].[pCheckOutDeliveryStop]
(
	@CurrentDeliveryStopID int,
	@CheckOutTime DateTime2(0),
	@DepartureTime DateTime2(0) = null,
	@Voided Bit = 0,
	@CheckOutLatitude Decimal(10,6) = 0.0,
	@CheckOutLongitude Decimal(10,6) = 0.0,
	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(50),
	@LastModifiedUTC DateTime2(0)
)
As
	Set NoCount On;

	If @DepartureTime Is Null
		Set @DepartureTime = @CheckOutTime

	Update Mesh.DeliveryStop
	Set	
		CheckOutTime = @CheckOutTime
		,Voided = @Voided
		,DepartureTime = @DepartureTime
		,CheckOutLatitude = @CheckOutLatitude
		,CheckOutLongitude = @CheckOutLongitude
		,LastModifiedBy = @LastModifiedBy
		,LastModifiedUTC = @LastModifiedUTC
		,LocalUpdateTime = SysDateTime()
	Where DeliveryStopID = @CurrentDeliveryStopID
	And DNS = 0

	If (@Voided = 1)
	Begin
		Insert Mesh.DeliveryStop
				   (PlannedStopID
				   ,DeliveryDateUTC
				   ,RouteID
				   ,Sequence
				   ,StopType
				   ,SAPAccountNumber
				   ,IsAddedByDriver
				   ,Quantity
				   ,PlannedArrival
				   ,ServiceTime
				   ,TravelToTime
				   ,Voided
				   ,DNSReasonCode
				   ,DNSReason
				   ,EstimatedArrivalTime
				   ,CheckInTime
				   ,ArrivalTime
				   ,CheckInFarAwayReasonID
				   ,CheckInDistance
				   ,CheckInLatitude
				   ,CheckInLongitude
				   ,EstimatedDepartureTime
				   ,CheckOutTime
				   ,DepartureTime
				   ,CheckOutLatitude
				   ,CheckOutLongitude
				   ,LastModifiedBy
				   ,LastModifiedUTC
				   ,LocalUpdateTime)
		 Select PlannedStopID
				   ,DeliveryDateUTC
				   ,RouteID
				   ,Sequence * (-1)
				   ,StopType
				   ,SAPAccountNumber
				   ,IsAddedByDriver
				   ,Quantity
				   ,PlannedArrival
				   ,ServiceTime
				   ,TravelToTime
				   ,Voided
				   ,DNSReasonCode
				   ,DNSReason
				   ,EstimatedArrivalTime
				   ,CheckInTime
				   ,ArrivalTime
				   ,CheckInFarAwayReasonID
				   ,CheckInDistance
				   ,CheckInLatitude
				   ,CheckInLongitude
				   ,EstimatedDepartureTime
				   ,CheckOutTime
				   ,DepartureTime
				   ,CheckOutLatitude
				   ,CheckOutLongitude
				   ,LastModifiedBy
				   ,LastModifiedUTC
				   ,LocalUpdateTime
		From Mesh.DeliveryStop
		Where DeliveryStopID = @CurrentDeliveryStopID

		Update Mesh.DeliveryStop
		Set CheckInTime = null
			,ArrivalTime = null
			,CheckInFarAwayReasonID = null
			,CheckInDistance = null
			,CheckInLatitude = null
			,CheckInLongitude = null
			,CheckOutTime = null
			,DepartureTime = null
			,CheckOutLatitude = null
			,CheckOutLongitude = null
			,Voided = 0
		Where DeliveryStopID = @CurrentDeliveryStopID
	End

	exec Mesh.pUpdateEstimatedArrivals @Estimates = @Estimates, @LastModifiedBy = @LastModifiedBy, @LastModifiedUTC = @LastModifiedUTC	

GO

Print 'Mesh.pCheckOutDeliveryStop created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pDeleteStop]
(
	@DeliveryStopID int
)
As
    Set NoCount On;

	If Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID)
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pDeleteStop}: Stop @DeliveryStopID=%i is not found', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID);
	End
	Else If Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And IsAddedByDriver = 0)
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pDeleteStop}: Stop @DeliveryStopID=%i is not added by driver', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID);
	End
	Else 
	Begin
		Delete
		From Mesh.DeliveryStop
		Where DeliveryStopID = @DeliveryStopID
		And IsAddedByDriver = 1
	End

GO

Print 'Mesh.pDeleteStop created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pDeliveryStopCheckIn]
(
	@CurrentDeliveryStopID int,
	@CheckInTime DateTime2(0),
	@ArrivalTime DateTime2(0) = null,
	@CheckInFarAwayReasonID int = null,
	@CheckInDistance Decimal(10,6) = 0.0,
	@CheckInLatitude Decimal(10,6) = 0.0,
	@CheckInLongitude Decimal(10,6) = 0.0,
	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(50),
	@LastModifiedUTC DateTime2(0)
)
As
	Set NoCount On;

	If @ArrivalTime Is Null
		Set @ArrivalTime = @CheckInTime

	Update Mesh.DeliveryStop
	Set	
		CheckInTime = @CheckInTime
		,ArrivalTime = @ArrivalTime
		,CheckInFarawayReasonID = @CheckInFarAwayReasonID
		,CheckInDistance = @CheckInDistance 
		,CheckInLatitude = @CheckInLatitude
		,CheckInLongitude = @CheckInLongitude
		,EstimatedDepartureTime = DateAdd(second, IsNull(ServiceTime, 0), @CheckInTime)
		,LastModifiedBy = @LastModifiedBy
		,LastModifiedUTC = @LastModifiedUTC
		,LocalUpdateTime = SysDateTime()
	Where DeliveryStopID = @CurrentDeliveryStopID

	exec Mesh.pUpdateEstimatedArrivals @Estimates = @Estimates, @LastModifiedBy = @LastModifiedBy, @LastModifiedUTC = @LastModifiedUTC	

GO

Print 'Mesh.pDeliveryStopCheckIn created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pGetDeliveryManifest]
(
	@RouteID int,
	@DeliveryDateUTC date = null
)
As
    Set NoCount On;

	Declare @DateString varchar(20)
	Declare @Value varchar(max)
	Declare @MeshEnabled bit
	Set @MeshEnabled = 0

	Select @Value = Value
	From Setup.Config
	Where [Key] = 'MeshEnabledBranches'

	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())

	If Exists (	Select *
		From dbo.udfSplit(@Value, ',') branches
		Join SAP.Branch b on branches.Value = b.SAPBranchId
		Join SAP.Route r on r.BranchID = b.BranchID
		And r.SAPRouteNumber = @RouteID)
	Begin 
		Set @MeshEnabled = 1
	End

	If @MeshEnabled = 1
	Begin
		Select Convert(varchar(10), DeliveryDateUTC) DeliveryDateUTC, 
			RouteID, @MeshEnabled MeshEnabled, TotalQuantity, PlannedStartTime, FirstName, LastName, PhoneNumber, PlannedCompleteTime, PlannedServicetime, PlannedTravelTime, PlannedBreakTime, PlannedPreRoutetime, PlannedPostRoutetime
		From Mesh.DeliveryRoute dr
		Where DeliveryDateUTC = @DeliveryDateUTC
		And RouteID = @RouteID

		Declare @IsStarted bit

		Select @IsStarted = IsStarted
		From Mesh.DeliveryRoute
		Where DeliveryDateUTC = @DeliveryDateUTC
		And RouteID = @RouteID

		If (@IsStarted = 0)
		Begin
			--------------------------------------------------------
			--CONSOLIDATE----CONSOLIDATE--CONSOLIDATE--CONSOLIDATE--
			Declare @Conso Table
			(
				PlannedStopID int
				,DeliveryDateUTC Date
				,RouteID int
				,Sequence int
				,StopType varchar(20)
				,SAPAccountNumber varchar(50)
				,Quantity int
				,PlannedArrival datetime2(0)
				,ServiceTime int
				,TravelToTime int
				,LastModifiedBy varchar(50)
				,LastModifiedUTC datetime2(0)
				,LocalUpdateTime datetime2(0)
			)

			Insert Into @Conso
			Select PlannedStopID
				,DeliveryDateUTC
				,RouteID
				,Sequence + 1 Sequence
				,StopType
				,SAPAccountNumber
				,Quantity
				,PlannedArrival
				,ServiceTime
				,TravelToTime
				,'Dispatcher' LastModifiedBy
				,LastModifiedUTC
				,GetDate() LocalUpdateTime
			From Mesh.PlannedStop
			Where DeliveryDateUTC = @DeliveryDateUTC And RouteID = @RouteID

			Declare @LastSAPAccountNumber varchar(50)
			Declare @SAPAccountNumber varchar(50)
			Declare @TravelToTime int
			Declare @ServiceTime int
			Declare @Cur int
			Declare @LastHitCur int
			Declare @MaxCur int
			Declare @Seq int
			Set @Cur = 0
			Select @MaxCur = Max(Sequence) From @Conso
			Select @LastSAPAccountNumber = @SAPAccountNumber From @Conso Where Sequence = @Cur
		
			While @Cur < @MaxCur
			Begin
				Set @Cur = @Cur + 1
				Select @LastHitCur	= Max(Sequence) From @Conso Where Sequence < @Cur

				Select @SAPAccountNumber = SAPAccountNumber, @TravelToTime = TravelToTime, @ServiceTime = ServiceTime From @Conso Where Sequence = @Cur
				--Select @Cur Cur, @SAPAccountNumber SAPAccountNumber, @TravelToTime TravelToTime
			
				If ((@LastSAPAccountNumber = @SAPAccountNumber) And (@TravelToTime = 0))
				Begin
					--Select SAPAccountNumber, Sequence From @Conso
					Update @Conso Set ServiceTime = ServiceTime + @ServiceTime Where Sequence = @LastHitCur
					Delete @Conso Where Sequence = @Cur
				End
				Select @LastSAPAccountNumber = @SAPAccountNumber

			End

			-- Need to adjust sequence ---
			Update c
			Set c.Sequence = t.RNum
			From @Conso c
			Join 
			(
			Select Row_Number() Over (Order By Sequence) As RNum, PlannedStopID
			From @Conso) t
			on c.PlannedStopID = t.PlannedStopID

			--Select * From @Conso

			----------------------------------------------------------
			--ENDofCONSOLIDATE----ENDofCONSOLIDATE--ENDofCONSOLIDATE--

			Merge Mesh.DeliveryStop As t
			Using @Conso as S
			On t.DeliveryDateUTC = s.DeliveryDateUTC And t.RouteID = s.RouteID And t.PlannedStopID = s.PlannedStopID
			When Matched 
				Then Update Set t.Sequence = s.Sequence
								,t.StopType = s.StopType
								,t.SAPAccountNumber = s.SAPAccountNumber
								,t.Quantity = s.Quantity
								,t.PlannedArrival = s.PlannedArrival
								,t.ServiceTime = s.ServiceTime
								,t.TravelToTime = s.TravelToTime
								,t.LastModifiedBy = s.LastModifiedBy
								,t.LastModifiedUTC = s.LastModifiedUTC
								,t.LocalUpdateTime = s.LocalUpdateTime
			When Not Matched By Source And t.DeliveryDateUTC = @DeliveryDateUTC And t.RouteID = @RouteID
				Then Delete
			When Not Matched By Target
				Then Insert (PlannedStopID
			   ,DeliveryDateUTC
			   ,RouteID
			   ,Sequence
			   ,StopType
			   ,SAPAccountNumber
			   ,Quantity
			   ,PlannedArrival
			   ,ServiceTime
			   ,TravelToTime
			   ,LastModifiedBy
			   ,LastModifiedUTC
			   ,LocalUpdateTime)
			   Values
				(s.PlannedStopID
			   ,s.DeliveryDateUTC
			   ,s.RouteID
			   ,s.Sequence
			   ,s.StopType
			   ,s.SAPAccountNumber
			   ,s.Quantity
			   ,s.PlannedArrival
			   ,s.ServiceTime
			   ,s.TravelToTime
			   ,s.LastModifiedBy
			   ,s.LastModifiedUTC
			   ,s.LocalUpdateTime);

			Update Mesh.DeliveryRoute
			Set LastManifestFetched = SysDateTime()
			Where RouteID = @RouteID and DeliveryDateUTC = @DeliveryDateUTC;

			--- Output ---
			Select DeliveryStopID
					,convert(varchar(10), DeliveryDateUTC) DeliveryDateUTC
					,RouteID
					,Sequence
					,ds.StopType, d.Description StopDescription
					,ds.SAPAccountNumber
					,Quantity
					,PlannedArrival
					,ServiceTime
					,TravelToTime
					,Latitude
					,Longitude
			From Mesh.DeliveryStop ds
			Join Mesh.StopTypeDesc d on ds.StopType = d.StopType 
			Left Join SAP.Account a with (nolock) on ds.SAPAccountNumber = a.SAPAccountNumber
			Where DeliveryDateUTC = @DeliveryDateUTC And RouteID = @RouteID
			Order By Sequence
		End
		Else
		Begin
			If (@IsStarted is null)
			Begin
				Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

				RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: No Manifest found for @RouteID=%i and @DeliveryDateUTC=%s.' , -- Message text.  
				   16, -- Severity,  
				   1, -- State,  
				   @RouteID, -- First argument.  
				   @DateString); -- Second argument.  
			End
			Else
			Begin
				Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

				RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: Manifest is not available for @RouteID=%i and @DeliveryDateUTC=%s, The Route has been checked out for the day and delivery plan has been updated from Checkout Driver.' , -- Message text.  
				   16, -- Severity,  
				   1, -- State,  
				   @RouteID, -- First argument.  
				   @DateString); -- Second argument.  
			End
		End

	End
	Else 
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)

		RAISERROR (N'[ClientDataError]{Mesh.pGetDeliveryManifest}: Meshnet solution is not enabled at branch for @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
	End


GO

Print 'Mesh.pGetDeliveryManifest created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pGetMaster]
As
    Set NoCount On;

	Select FarawayReasonID, ReasonDesc
	From Mesh.FarawayReason
	Where IsActive = 1

	Select ResequenceReasonID, ReasonDesc
	From Mesh.ResequenceReason
	Where IsActive = 1


GO

Print 'Mesh.pGetMaster created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pInsertInvoice]
(
	@Headers Mesh.tInvoiceHeaders ReadOnly,
	@Items Mesh.tInvoiceItems ReadOnly,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	Declare @TotalQuantity int, @InvoiceID int

	----------------------------------------
	--If @DeliveryDateUTC is null
	--	Set @DeliveryDateUTC = convert(date, GetUTCDate())

	----------------------------------------
	Insert Into Mesh.CustomerInvoice(DeliveryDateUTC, RMInvoiceID, RMOrderID, SAPBranchID, SAPAccountNumber, LastModifiedUTC, LastModifiedBy, LocalInsertTime)
	Select DeliveryDateUTC, RMInvoiceID, RMOrderID, SAPBranchID, SAPAccountNumber, @LastModifiedUTC, @LastModifiedBy, GetDate()
	From @Headers
	
	Insert Into Mesh.InvoiceItem(RMInvoiceID, ItemNumber, Quantity, LastModifiedUTC, LastModifiedBy, LocalInsertTime)
	Select RMInvoiceID, ItemNumber, Quantity, @LastModifiedUTC, @LastModifiedBy, GetDate()
	From @Items
	Where Quantity > 0;

	With Temp
	As
	(
		Select RMInvoiceID, Sum(Quantity) TotalQuantity
		From Mesh.InvoiceItem 
		Group By RMInvoiceID
	)

	Update ci
	Set TotalQuantity = t.TotalQuantity
	from Mesh.CustomerInvoice ci
	Join Temp t on ci.RMInvoiceID = t.RMInvoiceID

GO
Print 'Mesh.pInsertInvoice created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pInsertMeshMyDayLog]
(
	@WebEndPoint varchar(50)
	,@StoredProc varchar(50)
	,@CorrelationID varchar(32) = null
	,@GetParameters varchar(200) = null
	,@PostJson varchar(max) = null
	,@DeliveryDateUTC date = null
	,@RouteID int = null
	,@GSN varchar(50) = null
)
As
    Set NoCount On;

	If Exists (Select Value From Setup.Config Where [Key] = 'MeshMyDayLog' and Value = '1')
	Begin
		Insert Into Mesh.MyDayActivityLog
				   (WebEndPoint
				   ,StoredProc
				   ,GetParemeters
				   ,PostJson
				   ,RequestTime
				   ,CorrelationID
				   ,DeliveryDateUTC
				   ,RouteID
				   ,GSN)
			 VALUES
				   (@WebEndPoint, 
				   @StoredProc, 
				   @GetParameters, 
				   @PostJson, 
				   SysDateTime()
				   ,@CorrelationID
				   ,@DeliveryDateUTC
				   ,@RouteID
				   ,@GSN)
	End

	If (Datepart(dw, GetDate()) = 1) -- 1 is Sunday 
	Begin
		Declare @Cnt Int
		Select @Cnt = Count(*) From Mesh.MyDayActivityLog

		If (@Cnt > 150000)  -- Total Number Records > 150K 
		Begin
			Declare @CutOffDate Date
			Select @CutOffDate = DateAdd(Day, -60, GetDate())  -- CutOff to two month

			Select @CutOffDate
			Delete Mesh.MyDayActivityLog Where DeliveryDateUTC < @CutOffDate
		End
	End


GO

Print 'Mesh.pInsertMeshMyDayLog created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pUploadAddedStop]
(
	@RouteID int,
	@ServiceTime int,
	@DeliveryDateUTC date = null,
	@StopType varchar(20) = 'STP',
	@SAPAccountNumber varchar(20) = null,
	@Quantity int = 0,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------
	Declare @DateString varchar(20)
	
	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())

	If LTrim(RTrim(@StopType)) = ''
		Set @StopType = 'STP'

	----------------------------------------
	Declare @SequenceMax int
	
	Select @SequenceMax = Coalesce(Max(Sequence), 1)
	From Mesh.DeliveryStop
	Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC

	----------------------------------------	
	If Not Exists (Select * From Mesh.DeliveryRoute
		Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadAddedStop}: No route found for @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
	End
	Else If Exists (Select DeliveryStopID From Mesh.DeliveryStop
				Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC and SAPAccountNumber = @SAPAccountNumber)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadAddedStop}: Customer(%s) already exists in route (@RouteID=%i) and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
		   @SAPAccountNumber, -- First argument.  
           @RouteID, -- Second argument.
           @DateString); -- 
	End
	Else
	Begin
		Declare @DeliveryStopID int
		Insert Into Mesh.DeliveryStop(DeliveryDateUTC, RouteID, Sequence, IsAddedByDriver, StopType, ServiceTime, SAPAccountNumber, 
			Quantity, LastModifiedBy, LastModifiedUTC, LocalUpdateTime)
		Values (@DeliveryDateUTC, @RouteID, @SequenceMax+1, 1, @StopType, @ServiceTime, @SAPAccountNumber, @Quantity, @LastModifiedby, @LastModifiedUTC, GetDate())

		Select @DeliveryStopID = Scope_Identity()

		Select @DeliveryStopID DeliveryStopID, d.SAPAccountNumber, Latitude, Longitude
		From Mesh.DeliveryStop d
		Left Join SAP.Account a on d.SAPAccountNumber = a.SAPAccountNumber
		Where DeliveryStopID = @DeliveryStopID

	End
GO

Print 'Mesh.pUploadAddedStop created'
Go


-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pUploadNewSequence]
(
	@RouteID int,
	@DeliveryDateUTC date = null,

	@ResequenceReasonIDs varchar(500),
	@AddtionalReason varchar(200),

	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------
	Declare @DateString varchar(20)
	
	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())
	----------------------------------------

	Declare @MinSeq int, @MaxSeq int, @ResequenceID int

	----------------------------------------
	Select @MinSeq = Min(ds.Sequence), @MaxSeq = Max(ds.Sequence)
	From Mesh.DeliveryStop ds 
	Join @Estimates e on ds.DeliveryStopID = e.DeliveryStopID
	Where ds.Sequence <> e.Sequence

	Insert Into Mesh.Resequence
           (AddtionalReason
           ,RouteID
           ,DeliveryDateUTC
           ,StartSequenceID
           ,EndSequenceID
           ,LastModifiedBy
           ,LastModifiedUTC
           ,LocalUpdateTime)
     VALUES
           (@AddtionalReason
           ,@RouteID
           ,@DeliveryDateUTC
           ,@MinSeq
           ,@MaxSeq
           ,@LastModifiedBy 
           ,@LastModifiedUTC
           ,GetDate())

	Select @ResequenceID = Scope_Identity()
	----------------------------------------

	Insert Into Mesh.ResequeceReasons
           (ResequenceID
           ,ResequenceReasonID)
	Select @ResequenceID, Value ResequenceReasonID
	From Setup.udfSplit(@ResequenceReasonIDs, ',')
	----------------------------------------
	
	Insert Into Mesh.ResequenceDetail
			(ResequenceID
			,Sequence
			,OldEstimatedArrival
			,DeliveryStopID
			,NewSequence
			,NewEstimatedArrival)
	Select @ResequenceID, ds.Sequence,  Coalesce(ds.EstimatedArrivalTime, ds.PlannedArrival), e.DeliveryStopID, e.Sequence, e.EstimatedArrivalTime
	From Mesh.DeliveryStop ds 
	Join @Estimates e on ds.DeliveryStopID = e.DeliveryStopID
	Where ds.Sequence between Coalesce(@MinSeq, 0) and Coalesce(@Maxseq, 0)

	exec Mesh.pUpdateEstimatedArrivals @Estimates = @Estimates, @LastModifiedBy = @LastModifiedBy, @LastModifiedUTC = @LastModifiedUTC	


GO

Print 'Mesh.pUploadNewSequence created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pUploadRouteCheckout]
(
	@RouteID int,
	@ActualStartTime DateTime,
	@ActualStartGSN varchar(50),
	@FirstName varchar(50),
	@LastName varchar(50),
	@PhoneNumber varchar(50),
	@Latitude decimal(10, 7),
	@Longitude decimal(10, 7),
	@DeliveryDateUTC date = null,
	@LastModifiedUTC datetime2(0) = null
)
As
    Set NoCount On;

	Declare @OutputMessage varchar(100)
	Declare @DateString varchar(20)
		
	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())

	If @LastModifiedUTC is null
		Set @LastModifiedUTC = @ActualStartTime

	If Not Exists (Select DeliveryRouteID From Mesh.DeliveryRoute Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadRouteCheckout}: No route found for @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
		Return
	End

	If Not Exists ( Select *
		From Mesh.DeliveryStop
		Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadRouteCheckout}: Route manifest has not been fetched, or no stops scheduled for the route. @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
		Return
	End

	--If Not Exists (Select DeliveryRouteID From Mesh.DeliveryRoute Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC And IsStarted = 1)
	--Begin
		Update Mesh.DeliveryRoute
			Set ActualStartTime = @ActualStartTime,
				ActualStartGSN = @ActualStartGSN,
				ActualStartFirstname = @FirstName,
				ActualStartLastName	= @LastName,
				ActualStartPhoneNumber = @PhoneNumber,
				ActualStartLatitude = @Latitude,
				ActualStartLongitude = @Longitude,
				LastModifiedBy = @ActualStartGSN,
				LastModifiedUTC = @LastModifiedUTC,
				LocalSynctime = GetDate()
		Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC
		Set @OutputMessage = 'OK'
	--End
	--Else 
	--Begin
	--	Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
	--	RAISERROR (N'[ClientDataError]{Mesh.pUploadRouteCheckout}: Route has been checked out. @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
	--		16, -- Severity,  
	--		1, -- State,  
	--		@RouteID, -- First argument.  
	--		@DateString); -- Second argument.  
	--End

GO

Print 'Mesh.pUploadNewSequence created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

Create Proc [Mesh].[pUploadStopDNS]
(
	@DeliveryStopID int,
	@DNSReasonCode varchar(50),
	@DNSReason varchar(50) = null,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------	
	If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS not found @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And CheckInTime is not Null))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS is already checked-in @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And StopType = 'STP'))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS is not of type "STP" @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And DNS = 1))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS is DNSed already @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else 
	Begin
		Update ds Set
		ds.DNSReasonCode = @DNSReasonCode
		,ds.DNSReason = @DNSReason
		,ds.LastModifiedBy = @LastModifiedBy
		,ds.LastModifiedUTC = @LastModifiedUTC
		,ds.LocalUpdateTime = SysDateTime()
		From Mesh.DeliveryStop ds
		Where ds.DeliveryStopID = @DeliveryStopID

	End
GO

Print 'Mesh.pUploadStopDNS created'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/


SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Declare @Temp Bigint
Exec @Temp = Operation.pInsertBlob
	 @RelativeURL = '2016/09/14/default-636094429154152085.jpg'
	, @AbsoluteURL = 'https://mydpspoc.blob.core.windows.net/displaybuild/2016/09/14/default-736094429154152085.jpg'
	, @Container = 'displaybuild'
	, @StorageAccount = 'dpsappmerchandiser'

Select @Temp Temp

Need TESTING ---
*/

ALTER Proc Operation.pInsertBlob
(
	@RelativeURL varchar(250), 
	@AbsoluteURL varchar(250), 
	@Container varchar(250), 
	@StorageAccount varchar(250)
)
AS
BEGIN
	Set NoCount On
	----

	Declare @etval int
	Declare @NewBlobID bigint
	Declare @ContainerID int

	Select @ContainerID = ContainerID
	From Setup.AzureBlobContainer
	Where Container = @Container And StorageAccount = @StorageAccount

	If @ContainerID is null
	Begin
		Set @NewBlobID = -1
		RAISERROR ('No blob storage container found', -- Message text.  
        16, -- Severity.  
        1 -- State.  
        );  
	End
	Else If Exists (Select * From Operation.AzureBlobStorage Where @AbsoluteURL = AbsoluteURL)
	Begin
		Set @NewBlobID = -1
		-- RAISERROR ('Absolute URL exists, please request a new posting url and try again', 16, 1);  
	End
	Else
	Begin
		Insert Into Operation.AzureBlobStorage(ContainerID, RelativeURL, AbsoluteURL, IsOrphaned, LastModified)
		Values(@ContainerID, @RelativeURL, @AbsoluteURL, 0, SysDateTime())

		Select @NewBlobID = Scope_Identity();
	End

	Return @NewBlobID
END
Go

Print 'Operation.pInsertBlob altered'
Go

-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE [msdb]
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 6/18/2018 11:48:42 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'DPSG.SDM.JobContinuousDeliveryLoading.Merch.Import', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Load delivery schedule and orders periodically(see schedule, most likely hourly) and forever.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DPSG\SVC_SSIS_SHRDCLSTR', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Orders from RM]    Script Date: 6/18/2018 11:48:44 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Orders from RM(Route Manager)', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec ETL.pLoadOrderPeriodically', 
		@database_name=N'Merch', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Delivery Schedule from RN]    Script Date: 6/18/2018 11:48:44 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Delivery Schedule from RN(RoadNet)', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'ETL.pLoadDeliverySchedulePeriodically', 
		@database_name=N'Merch', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Hourly', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180206, 
		@active_end_date=99991231, 
		@active_start_time=001000, 
		@active_end_time=235959, 
		@schedule_uid=N'f63ce1e0-4208-4f48-9978-25d5db8b7ceb'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO

Print '-- $$$$ DPSG.SDM.ContinuousDeliveryLoading.Merch.Import Job Created $$$$--'
Go

Print '-- $$$$ ALL COMPLETED $$$$--'
Go


-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

Use Portal_Data
Go

Select *
From SAP.Branch
Where SAPBranchID = '1120'
Go

Set IDENTITY_INSERT Shared.Feature_Applications On
Insert Into Shared.Feature_Applications(ID, ApplicationID, ApplicationName, IsActive)
Values(2, 2, 'DRIVERMYDAY ', 1)
Set IDENTITY_INSERT Shared.Feature_Applications Off
Go

Set IDENTITY_INSERT Shared.Feature_Master On
Insert Into Shared.Feature_Master(FeatureID, FeatureName, ApplicationID, IsActive, IsCustomized)
Values(6, 'ESTIMATES', 2, 1, 1)
Set IDENTITY_INSERT Shared.Feature_Master Off
Go

Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
Values(6, 1120, 1)
Go

Select *
From Shared.Feature_Authorization
Where FeatureID = 6
Go

Use Merch
Go

Set IDENTITY_INSERT Setup.Config On
INSERT Setup.Config (ConfigID, [Key], Value, [Description], ModifiedDate, SendToMyday) VALUES (4, N'MeshEnabledBranches', N'1120', N'Mesh enabled branches in SAP Branch ID', CAST(N'2018-05-01 00:00:00.000' AS DateTime), 1)
GO
INSERT Setup.Config (ConfigID, [Key], Value, [Description], ModifiedDate, SendToMyday) VALUES (9, N'MeshMyDayLog', N'1', N'Enable log for MyDay activities for Mesh Delivery', CAST(N'2018-05-01 00:00:00.000' AS DateTime), 1)
GO
Set IDENTITY_INSERT Setup.Config Off
Go

Update Setup.Config
Set Value = '1120'
Where ConfigID = 4
Go

Select *
From Setup.Config
Go

USE [Merch]
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'B', N'Break')
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'DPT', N'Depot')
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'PB', N'Paid Break')
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'PL', N'Paid Layover')
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'PW', N'Paid Wait')
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'STP', N'Stop')
GO
INSERT [Mesh].[StopTypeDesc] ([StopType], [Description]) VALUES (N'W', N'Wait')
GO

Print '-- $$$$ Branch enabled [Waco] $$$$--'
Go


-------------------------------------------------------
/**        .'\   /`.
         .'.-.`-'.-.`.
    ..._:   .-. .-.   :_...
  .'    '-.(o ) (o ).-'    `.
 :  _    _ _`~(_)~`_ _    _  :
:  /:   ' .-=_   _=-. `   ;\  :
:   :|-.._  '     `  _..-|:   :
 :   `:| |`:-:-.-:-:'| |:'   :
  `.   `.| | | | | | |.'   .'
    `.   `-:_| | |_:-'   .'
      `-._   ````    _.-'
          ``-------''
----------- Keep going down the rabit hole. ----------**/

exec ETL.pLoadDeliverySchedulePeriodically
Go
exec ETL.pLoadOrderPeriodically
Go

-- final verification --
Select *
From Merch.ETL.DataLoadingLog
Go

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = Convert(Date, GetDate())
And RouteID like '1120%'
And TotalQuantity > 0
Go
