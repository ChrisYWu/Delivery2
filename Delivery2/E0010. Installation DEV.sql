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
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Config' and s.name = 'Smart')
Begin
	Drop Table Smart.Config
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.Config'
End
Go

Create Table Smart.Config
( 
	ConfigID int Primary Key,
	Descr varchar(128),
	Designation varchar(max),
	LastModified DateTime2(0)
)
Go

Insert Into Smart.Config
Values(1, 'Live indicator', '0', SysDateTime())

Insert Smart.Config
Values(4, 'Weekend Split', '0.5', SYSDATETIME())

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.Config created and initialized'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select *  From Shared.Feature_Master Where FeatureID = 8)
Begin
	Set IDENTITY_INSERT Shared.Feature_Master On
	Insert Into Shared.Feature_Master(FeatureID, FeatureName, ApplicationID, IsActive, IsCustomized)
	Values(8, 'SMARTORDER', 1, 1, 1)
	Set IDENTITY_INSERT Shared.Feature_Master Off

	Insert Shared.Feature_Authorization(FeatureID, BranchID, IsActive)
	Select 8, SAPBranchID, 1
	From SAP.Branch b
	Where SAPBranchID Not In
	(Select BranchID
	From Shared.Feature_Authorization fa 
	Where FeatureID = 6 )
	And SAPBranchID <> 'TJW1'
	Order By SAPBranchID

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  'Feature SMARTORDER added and initialized with all branches'

End
Else 
Begin
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  'Feature 8 existed? check what it is...'
	Select * From Shared.Feature_Master Where FeatureID = 8
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'ChainExclusion' and s.name = 'Smart')
Begin
	Drop Table Smart.ChainExclusion
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.ChainExclusion'
End
Go

Create Table Smart.ChainExclusion
( 
	ExclusionID int Identity(1,1) Primary Key,
	NationalChainID Int Null,
	RegionalChainID Int Null,
	LocalChainID Int Null,
	LastModified DateTime2(0) Default SysDateTime()
)
Go

Insert Into Smart.ChainExclusion(NationalChainID) Values (60)

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.ChainExclusion created and initialized(Walmart added)'
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
	STD float Null Default(0),
	Cap as Mean + STD,
	Sum2 float Null Default(0),
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
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Daily1' and s.name = 'Smart')
Begin
	Drop Table Smart.Daily1
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.Daily1'
End
Go

CREATE TABLE Smart.Daily1(
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	Sum1 float NULL Default(0),
	Cnt int NULL Default(0),
	Mean float NULL Default(0),
	STD float Null Default(0),
	Cap as Mean + STD,
	Sum2 float Null Default(0),
	Rate float NULL Default(0),
	Modified DateTime2(0) Null Default SysDateTime(),
	CONSTRAINT PK_SmartDaily1 PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC,
		SAPMaterialID ASC
	)
)

Go

CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate1 ON Smart.Daily1
(
	SAPAccountNumber ASC
)
INCLUDE (SAPMaterialID, Rate)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.Daily1 created'
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

------------------------------------------------------------
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pCaulcateRateQty' and s.name = 'Smart')
Begin
	Drop proc Smart.pCaulcateRateQty
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pCaulcateRateQty'
End 
Go

Create Proc Smart.pCaulcateRateQty
As 
Begin
	Set NoCount On

	Truncate Table Smart.Daily
	Drop INDEX NCI_SmartDaily_Rate ON Smart.Daily

	--@@@@--
	Insert Into Smart.Daily(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean, STD)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, AVG(Quantity) Mean, STDEV(Quantity) STD
	From Smart.SalesHistory
	Where SAPAccountNumber / 10000000 <> 5
	Group By SAPAccountNumber, SAPMaterialID
	Having Count(*) > 4;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Case When h.Quantity < d.Cap Then h.Quantity Else Cap End Capped
		From Smart.SalesHistory h
		Join Smart.Daily d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.Sum2 = t.Sum2, d.Rate = t.Sum2/90.0, d.Modified = SysDateTime()
	From Smart.Daily d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(Capped) Sum2
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate ON Smart.Daily
	(
		SAPAccountNumber ASC
	)
	INCLUDE (SAPMaterialID, Rate)

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pCaulcateRateQty created'
Go

------------------------------------------------------------
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pCaulcateRateQty1' and s.name = 'Smart')
Begin
	Drop proc Smart.pCaulcateRateQty1
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pCaulcateRateQty1'
End 
Go

Create Proc Smart.pCaulcateRateQty1
As 
Begin
	Set NoCount On

	Truncate Table Smart.Daily1
	Drop INDEX NCI_SmartDaily_Rate1 ON Smart.Daily1
	--@@@@--

	Insert Into Smart.Daily1(SAPAccountNumber, SAPMaterialID, Sum1, Cnt, Mean, STD)
	Select SAPAccountNumber, SAPMaterialID, Sum(Quantity) Sum1, Count(*) Cnt, AVG(Quantity) Mean, STDEV(Quantity) STD
	From Smart.SalesHistory
	Where SAPAccountNumber / 10000000 <> 5
	Group By SAPAccountNumber, SAPMaterialID
	Having Count(*) > 4;

	With Temp As
	(
		Select h.SAPAccountNumber, h.SAPMaterialID, Case When h.Quantity < d.Cap Then h.Quantity Else Cap End Capped
		From Smart.SalesHistory h
		Join Smart.Daily1 d on h.SAPAccountNumber = d.SAPAccountNumber And h.SAPMaterialID = d.SAPMaterialID
	)

	Update d
	Set d.Sum2 = t.Sum2, d.Rate = t.Sum2/90.0, d.Modified = SysDateTime()
	From Smart.Daily1 d 
	Join
	(
		Select SAPAccountNumber, SAPMaterialID, Sum(Capped) Sum2
		From Temp 
		Group By SAPAccountNumber, SAPMaterialID
	) t on d.SAPAccountNumber = t.SAPAccountNumber And d.SAPMaterialID = t.SAPMaterialID

	CREATE NONCLUSTERED INDEX NCI_SmartDaily_Rate1 ON Smart.Daily1
	(
		SAPAccountNumber ASC
	)
	INCLUDE (SAPMaterialID, Rate)

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pCaulcateRateQty1 created'
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

--CREATE TYPE Smart.tCustomerOrderInput AS TABLE(
--	SAPAccountNumber int not null,
--	DeliveryDate Date not null,
--	NextDeliveryDate Date not null,
--	PRIMARY KEY CLUSTERED 
--	(
--		SAPAccountNumber ASC
--	)WITH (IGNORE_DUP_KEY = OFF)
--)
--GO

--Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
--+ 'Type Smart.tCustomerOrderInput created'
--Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetSuggestedOrdersForCustomers' and s.name = 'Smart')
Begin
	Drop proc Smart.pGetSuggestedOrdersForCustomers
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pGetSuggestedOrdersForCustomers'
End 
Go

--Create Proc Smart.pGetSuggestedOrdersForCustomers
--(
--	@SAPAccounts Smart.tCustomerOrderInput ReadOnly,
--	@Debug Bit = 0
--)
--As 
--Begin
--	Set NoCount On;
	
--	Declare @Results Table
--	(
--		SAPAccountNumber int,
--		DeliveryDate Date,
--		NumberOfDays Int,
--		ItemNumber varchar(20),
--		Rate Float,
--		RawQty Float,
--		SuggestedQty Int
--	)

--	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
--	Declare @FilteredAccounts Table
--	(
--		SAPAccountNumber int not null,
--		DeliveryDate Date not null,
--		NextDeliveryDate Date not null
--	)

--	Insert Into @FilteredAccounts
--	Select *
--	From @SAPAccounts;

--	With localChainExclusion As (
--		Select lc.LocalChainID
--		From Smart.ChainExclusion ce
--		Join SAP.RegionalChain rc on ce.NationalChainID = rc.NationalChainID
--		Join SAP.LocalChain lc on rc.RegionalChainID = lc.RegionalChainID
--		Where ce.NationalChainID Is Not Null
--		Union
--		Select lc.LocalChainID
--		From Smart.ChainExclusion ce
--		Join SAP.LocalChain lc on ce.RegionalChainID = lc.RegionalChainID
--		Where ce.RegionalChainID Is Not Null
--		Union
--		Select ce.LocalChainID
--		From Smart.ChainExclusion ce
--		Where ce.LocalChainID Is Not Null
--	)

--	Delete @FilteredAccounts
--	Where SAPAccountNumber In (
--		Select SAPAccountNumber 
--		From SAP.Account a 
--		Join localChainExclusion lc on a.LocalChainID = lc.LocalChainID
--	)

--	If @Debug = 1
--	Begin
--		Select 'Accounts after filtered by chains' Step2
--		Select * From @FilteredAccounts Order by SAPAccountNumber
--	End
--	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

--	If Exists (Select * From Smart.Config Where ConfigID = 1 And Designation = 0)
--	Begin
--		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
--			+ 'Smart.pGetSuggestedOrdersForCustomers reads from Smart.Daily'
--		Insert Into @Results 
--		Select d.SAPAccountNumber, a.DeliveryDate, 
--			DateDiff(day, DeliveryDate, NextDeliveryDate) NumberOfDays, d.SAPMaterialID, Rate, Rate*DateDiff(day, DeliveryDate, NextDeliveryDate) RawQty,
--			Convert(Int, Case When Rate*(DateDiff(day, DeliveryDate, NextDeliveryDate)) < 1.0 Then 0 Else Round(Rate*DateDiff(day, DeliveryDate, NextDeliveryDate), 0) End) SuggestedQty
--		From @FilteredAccounts a 
--		Join Smart.Daily d on a.SAPAccountNumber = d.SAPAccountNumber
--	End
--	Else
--	Begin
--		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
--			+ 'Smart.pGetSuggestedOrdersForCustomers reads from Smart.Daily1'
--		Insert Into @Results 
--		Select d.SAPAccountNumber, a.DeliveryDate, 
--			DateDiff(day, DeliveryDate, NextDeliveryDate) NumberOfDays, d.SAPMaterialID, Rate, Rate*DateDiff(day, DeliveryDate, NextDeliveryDate) RawQty,
--			Convert(Int, Case When Rate*(DateDiff(day, DeliveryDate, NextDeliveryDate)) < 1.0 Then 0 Else Round(Rate*DateDiff(day, DeliveryDate, NextDeliveryDate), 0) End) SuggestedQty
--		From @FilteredAccounts a 
--		Join Smart.Daily1 d on a.SAPAccountNumber = d.SAPAccountNumber
--	End

--	Select SAPAccountNumber, DeliveryDate, ItemNumber, SuggestedQty
--	From @Results
--	Where SuggestedQty > 0
--	Order By SAPAccountNumber

--End
--Go

--Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
--+  'Proc Smart.pGetSuggestedOrdersForCustomers created'
--Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
IF TYPE_ID(N'Smart.tCustomerADD') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetADDsForCustomers' and s.name = 'Smart')
	Begin
		Drop proc Smart.pGetADDsForCustomers
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc Smart.pGetADDsForCustomers'
	End

	Drop Type Smart.tCustomerADD
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* Smart.tCustomerADD'
End
GO

CREATE TYPE Smart.tCustomerADD AS TABLE(
	SAPAccountNumber int not null
	PRIMARY KEY CLUSTERED 
	(
		SAPAccountNumber ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type Smart.tCustomerADD created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetADDsForCustomers' and s.name = 'Smart')
Begin
	Drop proc Smart.pGetADDsForCustomers
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc Smart.pGetADDsForCustomers'
End 
Go

Create Proc Smart.pGetADDsForCustomers
(
	@SAPAccounts Smart.tCustomerADD ReadOnly,
	@Debug Bit = 0
)
As 
Begin
	Set NoCount On;
	
	Declare @Results Table
	(
		SAPAccountNumber int,
		ItemNumber varchar(20),
		WeekendRate Float,
		WeekdayRate Float
	)

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	Declare @FilteredAccounts Table
	(
		SAPAccountNumber int not null
	)

	Insert Into @FilteredAccounts
	Select *
	From @SAPAccounts;

	With localChainExclusion As (
		Select lc.LocalChainID
		From Smart.ChainExclusion ce
		Join SAP.RegionalChain rc on ce.NationalChainID = rc.NationalChainID
		Join SAP.LocalChain lc on rc.RegionalChainID = lc.RegionalChainID
		Where ce.NationalChainID Is Not Null
		Union
		Select lc.LocalChainID
		From Smart.ChainExclusion ce
		Join SAP.LocalChain lc on ce.RegionalChainID = lc.RegionalChainID
		Where ce.RegionalChainID Is Not Null
		Union
		Select ce.LocalChainID
		From Smart.ChainExclusion ce
		Where ce.LocalChainID Is Not Null
	)

	Delete @FilteredAccounts
	Where SAPAccountNumber In (
		Select SAPAccountNumber 
		From SAP.Account a 
		Join localChainExclusion lc on a.LocalChainID = lc.LocalChainID
	)

	If @Debug = 1
	Begin
		Select 'Accounts after filtered by chains' Step1
		Select * From @FilteredAccounts Order by SAPAccountNumber
	End
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
	Declare @WeekendSplit Float
	Select @WeekendSplit = Coalesce(Designation, 0.5) From Smart.Config Where ConfigID = 4

	Declare @RoundDigit Int
	Set @RoundDigit = 4

	If Exists (Select * From Smart.Config Where ConfigID = 1 And Designation = 0)
	Begin
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
			+ 'Smart.pGetADDsForCustomers reads from Smart.Daily'
		Insert Into @Results 
		Select d.SAPAccountNumber, d.SAPMaterialID, Round(Rate * @WeekendSplit * 7.00 / 2.0, @RoundDigit) WeekendRate, 
													Round(Rate * (1.0 - @WeekendSplit) * 7.00 / 5.0, @RoundDigit) WeekdayRate
		From @FilteredAccounts a 
		Join Smart.Daily d on a.SAPAccountNumber = d.SAPAccountNumber
	End
	Else
	Begin
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
			+ 'Smart.pGetADDsForCustomers reads from Smart.Daily1'
		Insert Into @Results 
		Select d.SAPAccountNumber, d.SAPMaterialID, Round(Rate * @WeekendSplit * 7.00 / 2.0, @RoundDigit) WeekendRate, 
													Round(Rate * (1.0 - @WeekendSplit) * 7.00 / 5.0, @RoundDigit) WeekdayRate
		From @FilteredAccounts a 
		Join Smart.Daily1 d on a.SAPAccountNumber = d.SAPAccountNumber
	End

	Select SAPAccountNumber, ItemNumber, WeekendRate, WeekdayRate
	From @Results
	Order By SAPAccountNumber, ItemNumber

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc Smart.pGetADDsForCustomers created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-------------------------------------

If Not Exists (
	Select *
	From sys.columns c
	Join sys.tables t on c.object_id = t.object_id
	Where c.name = 'Source'
	And t.name = 'VoidOrderTracking'
)
Begin
	Alter Table DNA.VoidOrderTracking
	Add Source Varchar(128)

	CREATE NONCLUSTERED INDEX NCI_VoidOrderTracking_Source ON DNA.VoidOrderTracking
	(
		Source ASC
	)

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  'Adding column Source to table DNA.VoidOrderTracking'
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
Drop Proc DNA.pInsertVoidOrderDetails
Go
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  '* Proc DNA.pInsertVoidOrderDetails dropped'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
DROP TYPE DNA.utd_Void_OrderTracking
GO
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  '* Type DNA.utd_Void_OrderTracking dropped'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
CREATE TYPE DNA.utd_Void_OrderTracking AS TABLE(
	OrderNumber nvarchar(15) NOT NULL,
	SAPAccountNumber bigint NOT NULL,
	SAPMaterialID varchar(12) NOT NULL,
	ProposedQty int NOT NULL,
	OrderedQty int NOT NULL,
	VoidReasonCodeID int NOT NULL,
	OrderedBy varchar(50) NOT NULL,
	OrderDate datetime NOT NULL,
	Comments varchar(250) NULL,
	Source varchar(128) NULL,
	PRIMARY KEY CLUSTERED 
	(
		OrderNumber ASC,
		SAPMaterialID ASC
	) WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Type DNA.utd_Void_OrderTracking created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
Create PROCEDURE DNA.pInsertVoidOrderDetails(@tvpTable DNA.utd_Void_OrderTracking READONLY)
AS
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN
            --BEGIN TRAN UploadVoidOrder;
            DECLARE @SD INT;

            MERGE INTO DNA.VoidOrderTracking AS C1
            USING @tvpTable AS C2
            ON(C1.OrderNumber = C2.OrderNumber
               AND C1.SAPAccountNumber = C2.SAPAccountNumber
               AND C1.SAPMaterialID = C2.SAPMaterialID)
                WHEN MATCHED
                THEN UPDATE SET
                    C1.ProposedQty = C2.ProposedQty,
                    C1.OrderedQty = C2.OrderedQty,
                    C1.VoidReasonCodeID = C2.VoidReasonCodeID,
                    C1.OrderedBy = C2.OrderedBy,
                    C1.OrderDate = C2.OrderDate,
                    C1.InsertedBy = 'System',
                    C1.InsertDate = GETDATE(),
					C1.Comments = C2.Comments,
					C1.Source = Case When C2.Source is null Then 'POG' When RTRIM(LTRIM(C2.Source)) = '' Then 'POG' Else C2.Source End 
                WHEN NOT MATCHED
                THEN INSERT(OrderNumber,
                    SAPAccountNumber,
                    SAPMaterialID,
                    ProposedQty,
                    OrderedQty,
                    VoidReasonCodeID,
                    OrderedBy,
                    OrderDate,
                    InsertedBy,
                    InsertDate,
					Comments,
					Source) VALUES
            (C2.OrderNumber,
             C2.SAPAccountNumber,
             C2.SAPMaterialID,
             C2.ProposedQty,
             C2.OrderedQty,
             C2.VoidReasonCodeID,
             C2.OrderedBy,
             C2.OrderDate,
             'System',
             GETDATE(),
			 C2.Comments,
			 Case When C2.Source is null Then 'POG' When RTRIM(LTRIM(C2.Source)) = '' Then 'POG' Else C2.Source End
            );

            MERGE INTO DNA.Snoozing AS C1
            USING @tvpTable AS C2
            ON(C1.SAPAccountNumber = C2.SAPAccountNumber
               AND C1.SAPMaterialID = C2.SAPMaterialID)
                WHEN MATCHED
                THEN UPDATE SET
                                C1.InsertedBy = 'System',
                                C1.InsertDate = GETDATE(),
                                C1.SnoozeDate =
            (
                SELECT DATEADD(day, SnoozeDuration, GETDATE())
                FROM DNA.VoidReasonCode
                WHERE VoidReasonCodeId = C2.VoidReasonCodeID
            )
                WHEN NOT MATCHED
                THEN INSERT(SAPAccountNumber,
                            SAPMaterialID,
                            InsertedBy,
                            InsertDate,
                            SNOOZEDATE) VALUES
            (C2.SAPAccountNumber,
             C2.SAPMaterialID,
             'System',
             GETDATE(),
            (
                SELECT DATEADD(day, SnoozeDuration, GETDATE())
                FROM DNA.VoidReasonCode
                WHERE VoidReasonCodeId = C2.VoidReasonCodeID
            )
            );

            --COMMIT TRAN UploadVoidOrder;
        END;
    END TRY
    BEGIN CATCH
        DECLARE @msg NVARCHAR(2048)= ERROR_MESSAGE(), @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        RAISERROR(@msg, 16, 1);
        SELECT @ErrorMessage = ERROR_MESSAGE(),
               @ErrorSeverity = ERROR_SEVERITY(),
               @ErrorState = ERROR_STATE();
    END CATCH;
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc DNA.pInsertVoidOrderDetails updated'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
Update DNA.VoidOrderTracking
Set Source = 'POG'
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Column [Source] on table DNA.VoidOrderTracking updated with default value POG'
Go


--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
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
or name = 'KDP.SDM.JobSalesHistoryForPredictiveOrders.Portal_Data.Import'

If @JobID is not null 
Begin
	EXEC msdb.dbo.sp_delete_job @job_id=@JobID, @delete_unused_schedule=1

	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Agent Job KDP.SDM.JobSalesHistoryForPredictiveOrders.Portal_Data.Import deleted with schedule'
End
GO

BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
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
		@active_start_time=5900, 
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
