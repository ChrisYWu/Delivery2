Use Portal_Data
Go
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Connectoion set to Portal_Data'
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
If Not Exists (Select * From sys.schemas Where Name = 'Smart')
Begin
	exec('Create Schema Smart')
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'SalesHistory' and s.name = 'Smart')
Begin
	Drop Table Smart.SalesHistory
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.SalesHistory'
End
Go

CREATE TABLE Smart.SalesHistory(
	DeliveryDate date NOT NULL,
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	Quantity float NOT NULL,
	CONSTRAINT PK_SalesHistory PRIMARY KEY CLUSTERED 
	(
		DeliveryDate ASC,
		SAPAccountNumber ASC,
		SAPMaterialID ASC
	)
) 

Go

CREATE NONCLUSTERED INDEX NCI_SmartSalesHistory_Account_Material ON Smart.SalesHistory
(
	SAPAccountNumber ASC,
	SAPMaterialID ASC
)
INCLUDE (Quantity)
GO

CREATE NONCLUSTERED INDEX NCI_SmartSalesHistory_DeliveryDate ON Smart.SalesHistory
(
	DeliveryDate ASC
)
INCLUDE (Quantity)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.SalesHistory created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Daily' and s.name = 'Smart')
Begin
	Drop Table Smart.Daily
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.Daily'
End
Go

CREATE TABLE Smart.Daily(
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	Sum1 float NULL Default(0),
	Cnt int NULL Default(0),
	Mean float NULL Default(0),
	DiffSQR float Null Default(0),
	Comp float Null Default(0),
	STD float NULL Default(0),
	Error float NULL Default(0),
	Rate float NULL Default(0),
	Modified DateTime2(0) Null Default SysDateTime(),
	CONSTRAINT PK_SmartDaily PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC,
		SAPMaterialID ASC
	)
)

Go

CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate ON Smart.Daily
(
	SAPAccountNumber ASC
)
INCLUDE (SAPMaterialID, Rate)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.Daily created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'DeliveryDateRange' and s.name = 'Smart')
Begin
	Drop Table Smart.DeliveryDateRange
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.DeliveryDateRange'
End
Go

CREATE TABLE Smart.DeliveryDateRange(
	DeliveryDate Date Not Null,
	RecordCount Int,
	InRange bit, 
	DayOfWeek As DATENAME(dw, DeliveryDate),	
	Constraint PK_DeliveryDateRange Primary Key Clustered
	(
		DeliveryDate ASC
	)
)

Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.DeliveryDateRange created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpdateDateRange' and s.name = 'Smart')
Begin
	Drop proc Smart.pUpdateDateRange
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pUpdateDateRange'
End 
Go

Create Proc Smart.pUpdateDateRange
As
Begin
	Set NoCount On;
	Declare @StartDate Date
	Declare @EndDate Date
	Set @EndDate = Convert(Date, SysDateTime()) -- Today
	Set @StartDate = DateAdd(Day, -90, Convert(Date, SysDateTime())) -- 90 Days Range

	While @StartDate < @EndDate -- The Range is close on the smaller end and open on the larger, so it's 90 days counter from yesterday
	Begin
		If Not Exists (Select * From Smart.DeliveryDateRange Where DeliveryDate = @StartDate)
		Begin
			Insert Smart.DeliveryDateRange(DeliveryDate, RecordCount, InRange)
			Values(@StartDate, 0, 1)
		End
		Select @StartDate = DateAdd(Day, 1, @StartDate)
	End

	Update r
	Set r.RecordCount = h.Cnt
	From 
	Smart.DeliveryDateRange r
	Join
		(
		Select DeliveryDate, Count(*) Cnt
		From Smart.SalesHistory   
		Group By DeliveryDate
	) h on r.DeliveryDate = h.DeliveryDate

	Set @StartDate = DateAdd(Day, -90, Convert(Date, SysDateTime())) -- 90 Days Range
	Update Smart.DeliveryDateRange
	Set InRange = 0
	Where DeliveryDate < @StartDate

	Select 'Deleting Smart.SalesHistory for delivery date < ' + convert(Varchar(10), @StartDate)

	Delete Smart.SalesHistory
	Where DeliveryDate < @StartDate
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pUpdateDateRange created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pCaulcateRateQty' and s.name = 'Smart')
Begin
	Drop proc Smart.pCaulcateRateQty
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pCaulcateRateQty'
End 
Go

Create Proc Smart.pCaulcateRateQty
(
	@ZScore Float = 0.842,   --This is Z60
	@SampleSize int = 90
)
As 
Begin
	Set NoCount On

	Declare @Bessel Int
	Set @Bessel = @SampleSize - 1

	Truncate Table Smart.Daily
	--@@@@--
	Drop Index NCI_SmartDaily_Rate ON Smart.Daily

	Insert Into Smart.Daily(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, Sum(Quantity)/@SampleSize Mean
	From Smart.SalesHistory
	Group By SAPAccountNumber, SAPMaterialID;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Square(h.Quantity - d.Mean) SQR
		From Smart.SalesHistory h
		Join Smart.Daily d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.DiffSQR = t.DiffSQR
	From Smart.Daily d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(SQR) DiffSQR
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	-- Sqrt(90) = 9.48683298050514
	Update Smart.Daily
	Set Comp = (@SampleSize - Cnt) * Square(Mean)

	Update Smart.Daily
	Set STD = Sqrt((DiffSQR + Comp)/@Bessel)

	Update Smart.Daily
	Set Error = STD/9.48683298050514, Rate = Mean - @Zscore*STD/9.48683298050514, Modified = SysDateTime()

	--@@@@--
	Create NONCLUSTERED INDEX NCI_SmartDaily_Rate ON Smart.Daily
	(
		SAPAccountNumber ASC
	)
	INCLUDE (SAPMaterialID, Rate)
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pCaulcateRateQty created'
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

		Select @LatestLoadDeliveryDate = Coalesce(Max(EndDeliveryDate), GetDate())
		From ETL.DataLoadingLog l
		Where SchemaName = 'Staging' And TableName = 'RMDailySale'
		And l.IsMerged = 1

		DEclare @StartDeliveryDate Date
		Select @StartDeliveryDate = DateAdd(Day, -1, @LatestLoadDeliveryDate)  -- Include that last loaded day to create one day overlap
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
		Delete Smart.SalesHistory
		Where DeliveryDate In (Select Distinct DeliveryDate From Staging.RMDailySale)

		Insert Smart.SalesHistory
		Select DeliveryDate, SAPAccountNumber, SAPMaterialID, Quantity
		From Staging.RMDailySale

		Update ETL.DataLoadingLog 
		Set MergeDate = SysDateTime()
		Where LogID = @LogID

		-----------------------------------
		exec Smart.pUpdateDateRange
		Update ETL.DataLoadingLog 
		Set AdjustRangeDate = SysDateTime()
		Where LogID = @LogID

		-----------------------------------
		exec Smart.pCaulcateRateQty

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


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
IF TYPE_ID(N'Smart.tCustomerOrderInput') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetSuggestedOrdersForCustomers' and s.name = 'Smart')
	Begin
		Drop proc Smart.pGetSuggestedOrdersForCustomers
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc Smart.pGetSuggestedOrdersForCustomers'
	End

	Drop Type Smart.tCustomerOrderInput
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* Smart.tCustomerOrderInput'
End
GO

CREATE TYPE Smart.tCustomerOrderInput AS TABLE(
	SAPAccountNumber int not null,
	DeliveryDate Date not null,
	NextDeliveryDate Date not null,
	PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type Smart.tCustomerOrderInput created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetSuggestedOrdersForCustomers' and s.name = 'Smart')
Begin
	Drop proc Smart.pGetSuggestedOrdersForCustomers
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pGetSuggestedOrdersForCustomers'
End 
Go

Create Proc Smart.pGetSuggestedOrdersForCustomers
(
	@SAPAccounts Smart.tCustomerOrderInput ReadOnly
)
As 
Begin
	Set NoCount On;
	
	Declare @Results Table
	(
		SAPAccountNumber int,
		DeliveryDate Date,
		NumberOfDays Int,
		ItemNumber varchar(20),
		Rate Float,
		RawQty Float,
		SuggestedQty Int
	)

	Insert Into @Results 
	Select d.SAPAccountNumber, a.DeliveryDate, DateDiff(day, DeliveryDate, NextDeliveryDate) NumberOfDays, d.SAPMaterialID, Rate, Rate*DateDiff(day, DeliveryDate, NextDeliveryDate) RawQty,
	Convert(Int, Case When Rate*(DateDiff(day, DeliveryDate, NextDeliveryDate)) < 1.0 Then 0 Else Round(Rate*DateDiff(day, DeliveryDate, NextDeliveryDate), 0) End) SuggestedQty
	From @SAPAccounts a 
	Join Smart.Daily d on a.SAPAccountNumber = d.SAPAccountNumber

	Select SAPAccountNumber, DeliveryDate, ItemNumber, SuggestedQty
	From @Results
	Where SuggestedQty > 0

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pGetSuggestedOrdersForCustomers created'
Go

-------------------------------------
USE [msdb]
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Connectoion set to msdb'
Go


Declare @JobID varchar(100)
Select @JobID = job_id
From dbo.sysjobs
Where name = 'KDP.SDM.JobSalesHistoryForPredictiveOrders'

If @JobID is not null 
Begin
	EXEC msdb.dbo.sp_delete_job @job_id=@JobID, @delete_unused_schedule=1
End
GO

/****** Object:  Job [001Test.SalesHistoryFromInvoice]    Script Date: 2/13/2019 10:07:12 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 2/13/2019 10:07:12 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'KDP.SDM.JobSalesHistoryForPredictiveOrders', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'OnePortal', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [exec ETL.pLoadRMDailySale]    Script Date: 2/13/2019 10:07:13 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'exec ETL.pLoadRMDailySale', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'exec ETL.pLoadRMDailySale', 
		@database_name=N'Portal_Data', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'12:45 am at night once a day', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20180816, 
		@active_end_date=99991231, 
		@active_start_time=4500, 
		@active_end_time=235959, 
		@schedule_uid=N'5ff167cf-3008-4bdf-b8a6-9cff34a2187a'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Agent Job KDP.SDM.JobSalesHistoryForPredictiveOrders created'
Go