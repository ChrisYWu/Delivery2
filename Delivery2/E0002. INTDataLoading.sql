Use Portal_Data
Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'RMDailySale' and s.name = 'Staging')
Begin
	Drop Table Staging.RMDailySale
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Staging.RMDailySale'
End
Go

Create Table Staging.RMDailySale
( 
	DeliveryDate Date,
	SAPAccountNumber bigint,
	SAPMaterialID varchar(12),
	Quantity Float
)
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Staging.RMDailySale created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.objects p join sys.schemas s on p.schema_id = s.schema_id Where p.name = 'udfConvertToPLSqlTimeFilter' and s.name = 'dbo' and type IN ('FN', 'IF', 'TF') )
Begin
	DROP FUNCTION dbo.udfConvertToPLSqlTimeFilter
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping function dbo.udfConvertToPLSqlTimeFilter'
End 
Go

CREATE Function dbo.udfConvertToPLSqlTimeFilter
(
	@InputTime DateTime
)
Returns Varchar(200)
As
	Begin
		Declare @retval varchar(200)
		Set @retval = ''''''
		Set @retval += convert(varchar(10), @InputTime, 120)
		Set @retval += ''''''

		Return @retval
	End
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Function dbo.udfConvertToPLSqlTimeFilter created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'DataLoadingLog' and s.name = 'ETL')
Begin
	Drop Table ETL.DataLoadingLog
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table ETL.DataLoadingLog'
End
Go

CREATE TABLE ETL.DataLoadingLog(
	LogID bigint IDENTITY(1,1) NOT NULL,
	LogDate  AS (CONVERT(date,StartDate)),
	IsMerged  AS (CONVERT(bit,case when MergeDate IS NULL then (0) else (1) end)),
	IsProcessed  AS (CONVERT(bit,case when ProcessDate IS NULL then (0) else (1) end)),
	LoadingTimeInSeconds AS (datediff(second,StartDate,EndDate)),
	MergingTimeInSeconds As DateDiff(s, EndDate, MergeDate),
	DeleteTimeInSeconds As DateDiff(s, MergeDate, AdjustRangeDate),
	ProcessingTimeInSeconds As DateDiff(s, AdjustRangeDate, ProcessDate),
	TableName varchar(100) NOT NULL,
	SchemaName varchar(50) NOT NULL,
	StartDate datetime2(0) NOT NULL,
	EndDate datetime2(0) NULL,
	MergeDate datetime2(0) NULL,
	AdjustRangeDate datetime2(0) Null,
	ProcessDate datetime2(0) NULL,
	NumberOfRecordsLoaded int NULL,
	StartDeliveryDate date NULL,
	EndDeliveryDate date NULL,
	Query nvarchar(1000) NULL,
	ErrorMessage varchar(4000) NULL,
	 CONSTRAINT PK_DSDDataLoadingLog PRIMARY KEY CLUSTERED 
	(
		StartDate DESC,
		SchemaName ASC,
		TableName ASC
	)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table ETL.DataLoadingLog created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pLoadRMDailySale' and s.name = 'ETL')
Begin
	Drop proc ETL.pLoadRMDailySale
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc ETL.pLoadRMDailySale'
End 
Go

Create proc ETL.pLoadRMDailySale
As
Begin
	SET NOCOUNT ON;  
	Declare @Query varchar(4096)
	Declare @LatestLoadDeliveryDate Date
	Declare @DateRangeString varchar(1024)
	Declare @RecordCount int
	Declare @LastRecordDate DateTime
	Declare @LogID bigint

	--------------------------------------------
	Begin Try
		Truncate Table Staging.RMDailySale

		Select @LatestLoadDeliveryDate = Coalesce(Max(EndDeliveryDate), DateAdd(Day, -1, GetDate()))
		From ETL.DataLoadingLog l
		Where SchemaName = 'Staging' And TableName = 'RMDailySale'
		And l.IsMerged = 1

		DEclare @StartDeliveryDate Date
		Select @StartDeliveryDate = DateAdd(Day, -1, @LatestLoadDeliveryDate)
		Select @DateRangeString = dbo.udfConvertToPLSqlTimeFilter(@StartDeliveryDate)

		Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
		Values ('Staging', 'RMDailySale', SysDateTime())
		Select @LogID = SCOPE_IDENTITY()

		-------------------------------------------------
		Set @Query = 'Insert Into Staging.RMDailySale Select * From OpenQuery(' 
		Set @Query += 'RM' +  ', ''';
		Set @Query += 'SELECT IV.DELIVERY_DATE DELIVERY_DATE, '
		Set @Query += 'IV.CUSTOMER_NUMBER ACCOUNT_NUMBER, ID.ITEM_NUMBER, '
		Set @Query += 'SUM(ID.CASEQTY) DELIVERYCASEQTY '
		Set @Query += 'FROM ACEUSER.INVOICE_MASTER IV, ACEUSER.INVOICE_DETAIL ID, ACEUSER.ITEM_MASTER IM  '
		Set @Query += 'WHERE TO_CHAR(IV.DELIVERY_DATE, ''''YYYY-MM-DD'''') > '
		Set @Query += @DateRangeString
		Set @Query += ' AND TO_CHAR(IV.DELIVERY_DATE, ''''YYYY-MM-DD'''') <  '
		Set @Query += dbo.udfConvertToPLSqlTimeFilter(SysDateTime())
		Set @Query += ' AND IV.ORDER_STATUS IN (6,7) '
		Set @Query += 'AND IV.INVOICE_NUMBER = ID.INVOICE_NUMBER '             
		Set @Query += 'AND IV.TYPE = ''''D'''' '
		Set @Query += 'AND ID.CASEQTY > 0 '
		Set @Query += 'AND ID.ITEM_NUMBER = IM.ITEM_NUMBER '
		Set @Query += 'AND IV.LOCATION_ID = IM.LOCATION_ID '
		Set @Query += 'AND IM.MATERIAL_TYPE IN (''''FERT'''', ''''HAWA'''') '
		--Set @Query += 'AND rownum < 10 '
		Set @Query += 'GROUP BY IV.LOCATION_ID, IV.CUSTOMER_NUMBER, IV.DELIVERY_DATE, ID.ITEM_NUMBER '
		Set @Query += ''')'	

		Update ETL.DataLoadingLog 
		Set Query = @Query
		Where LogID = @LogID

		Exec(@Query)

		----------------------------------
		Select @RecordCount = Count(*), @StartDeliveryDate = Min(DeliveryDate), @LastRecordDate = Max(DeliveryDate) 
		From Staging.RMDailySale

		Update ETL.DataLoadingLog 
		Set EndDate = SysDateTime(), NumberOfRecordsLoaded = @RecordCount, EndDeliveryDate = @LastRecordDate, StartDeliveryDate = @StartDeliveryDate
		Where LogID = @LogID

		-----------------------------------
		Drop INDEX NCI_SmartSalesHistory_Account_Material ON Smart.SalesHistory
		Drop INDEX NCI_SmartSalesHistory_DeliveryDate ON Smart.SalesHistory

		Delete Smart.SalesHistory
		Where DeliveryDate In (Select Distinct DeliveryDate From Staging.RMDailySale)

		Insert Smart.SalesHistory
		Select DeliveryDate, SAPAccountNumber, SAPMaterialID, Quantity
		From Staging.RMDailySale

		----
		Delete Smart.OrderTracking  
		Output DELETED.*
		Into Smart.OrderTrackingHistory

		Delete
		From Smart.OrderTrackingHistory
		Where OrderDate <= DateAdd(Day, -546, GetDate())
		----

		Update ETL.DataLoadingLog 
		Set MergeDate = SysDateTime()
		Where LogID = @LogID

		-----------------------------------
		CREATE NONCLUSTERED INDEX NCI_SmartSalesHistory_Account_Material ON Smart.SalesHistory
		(
			SAPAccountNumber ASC,
			SAPMaterialID ASC
		)
		INCLUDE (Quantity)

		CREATE NONCLUSTERED INDEX NCI_SmartSalesHistory_DeliveryDate ON Smart.SalesHistory
		(
			DeliveryDate ASC
		)
		INCLUDE (Quantity)

		exec Smart.pUpdateDateRange
		
		Update ETL.DataLoadingLog 
		Set AdjustRangeDate = SysDateTime()
		Where LogID = @LogID
		-----------------------------------
		If Exists (Select * From Smart.Config Where ConfigID = 1 And Designation = 1)
		Begin
			exec Smart.pCaulcateRateQty
			Update Smart.Config Set Designation = 0, LastModified = SYSDATETIME() Where ConfigID = 1 
		End
		Else 
		Begin
			exec Smart.pCaulcateRateQty1
			Update Smart.Config Set Designation = 1, LastModified = SYSDATETIME() Where ConfigID = 1 
		End

		Update ETL.DataLoadingLog 
		Set ProcessDate = SysDateTime()
		Where LogID = @LogID

	End Try
	Begin Catch
		Declare @ErrorMessage varchar(200)
		Select @ErrorMessage = Error_Message()

		Update ETL.DataLoadingLog 
		Set ErrorMessage = @ErrorMessage
		Where LogID = @LogID
	End Catch
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'ETL.pLoadRMDailySale Created'
Go

exec ETL.pLoadRMDailySale
Go


