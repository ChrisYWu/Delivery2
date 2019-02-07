Use Portal_Data
Go

--Select @@SERVERNAME Server, DB_Name() As Database
--Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select * From sys.schemas Where Name = 'Smart')
Begin
	exec('Create Schema Smart')
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'SaleHistory' and s.name = 'Smart')
Begin
	Drop Table Smart.SaleHistory
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table Smart.SaleHistory'
End
Go

Create Table Smart.SaleHistory
( 
	DeliveryDate Date,
	SAPAccountNumber bigint,
	SAPMaterialID varchar(12),
	Quantity Float
)
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table Smart.SaleHistory created'
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
	LastLoadingTimeInSeconds  AS (datediff(second,StartDate,EndDate)),
	IsMerged  AS (CONVERT(bit,case when LocalMergeDate IS NULL then (0) else (1) end)),
	TableName varchar(100) NOT NULL,
	SchemaName varchar(50) NOT NULL,
	StartDate datetime2(0) NOT NULL,
	EndDate datetime2(0) NULL,
	NumberOfRecordsLoaded int NULL,
	LatestDeliveryDate date NULL,
	LocalMergeDate datetime2(0) NULL,
	Query nvarchar(1000) NULL,
	ErrorStep varchar(50) NULL,
	ErrorMessage varchar(250) NULL,
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
	Declare @Query varchar(1024)
	Declare @LatestLoadDeliveryDate Date
	Declare @DateRangeString varchar(1024)
	Declare @RecordCount int
	Declare @LastRecordDate DateTime
	Declare @LogID bigint

	--------------------------------------------

	Truncate Table Staging.RMDailySale

	Select @LatestLoadDeliveryDate = Coalesce(Max(LatestDeliveryDate), GetDate())
	From ETL.DataLoadingLog l
	Where SchemaName = 'Staging' And TableName = 'RMDailySale'
	And l.IsMerged = 1

	Select @DateRangeString = dbo.udfConvertToPLSqlTimeFilter(DateAdd(Day, -2, @LatestLoadDeliveryDate))

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
	Set @Query += ' AND IV.ORDER_STATUS IN (6,7) '
	Set @Query += 'AND SUBSTR(ID.ITEM_NUMBER, 1, 1) IN (1,2) '
	Set @Query += 'AND IV.INVOICE_NUMBER = ID.INVOICE_NUMBER '             
	Set @Query += 'AND IV.TYPE = ''''D'''' '
	Set @Query += 'AND ID.CASEQTY > 0 '
	Set @Query += 'AND ID.ITEM_NUMBER = IM.ITEM_NUMBER '
	Set @Query += 'AND IV.LOCATION_ID = IM.LOCATION_ID '
	Set @Query += 'IM.MATERIAL_TYPE IN (''''FERT'''', ''''HAWA'''') '
	--Set @Query += 'AND rownum < 10 '
	Set @Query += 'GROUP BY IV.LOCATION_ID, IV.CUSTOMER_NUMBER, IV.DELIVERY_DATE, ID.ITEM_NUMBER '
	Set @Query += ''')'	
	
	--Select(@Query)
	Exec(@Query)

	Select @RecordCount = Count(*) From Staging.RMDailySale
	Select @LastRecordDate = Max(DeliveryDate) From Staging.RMDailySale

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestDeliveryDate = @LastRecordDate, Query = @Query
	Where LogID = @LogID

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'ETL.pLoadRMDailySale Created'
Go

--EXEC ETL.pLoadRMDailySale

