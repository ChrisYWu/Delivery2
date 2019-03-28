Use Merch
Go

If Not Exists (Select * From Setup.Config Where ConfigID = 11)
Begin
	Set Identity_Insert Setup.Config On
	Insert Setup.Config(ConfigID, [Key], [Value], [Description], ModifiedDate, SendToMyday)
	Values(11, 'APNSForDeliveryUpdates', '', 'APNS for delivery updates in SAP Branch ID', GetDate(), 0)
	Set Identity_Insert Setup.Config Off
End
Go

Declare @V Varchar(8000)
Set @V = '' 

Select @V = @V + Convert(Varchar(10), SAPBranchID) + ','
From SAP.Branch
Where SAPBranchID <> 'TJW1'
Order By BranchID

Update Merch.Setup.Config
Set Value = SUBSTRING(@V, 1, Len(@V) - 1)
Where ConfigID = 11
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Setup APNSEnabledBranchesForDeliveryUpdates added'

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select * From sys.schemas Where Name = 'APNSMerch')
Begin
	exec('Create Schema APNSMerch')
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  'Schema APNSMerch created'
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'DeliveryInfo' and s.name = 'APNSMerch')
Begin
	Drop Table APNSMerch.DeliveryInfo
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table APNSMerch.DeliveryInfo'
End
Go

Create Table APNSMerch.DeliveryInfo(
	DeliveryDateUTC date NOT NULL,
	SAPAccountNumber int NOT NULL,
	MerchandiserGSN varchar(50) NOT NULL,
	ArrivalTime datetime2(0) NULL,
	KnownArrivalTime datetime2(0) NULL,
	IsEstimated bit NOT NULL,
	Delta As (datediff(second,KnownArrivalTime,ArrivalTime)),
	DNS bit NULL,
	KnownDNS bit null,
	LastModifiedBy varchar(50) NOT NULL,
	LastModified DateTime2(0) Not Null
	Constraint PK_DeliveryInfo Primary Key Clustered
	(
		DeliveryDateUTC DESC,
		SAPAccountNumber ASC,
		MerchandiserGSN ASC
	)
) 
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table DeliveryInfo created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'StoreDeliveryTimeTrace' and s.name = 'APNSMerch')
Begin
	Drop Table APNSMerch.StoreDeliveryTimeTrace
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table APNSMerch.StoreDeliveryTimeTrace'
End
Go

Create Table APNSMerch.StoreDeliveryTimeTrace(
	DeliveryDateUTC date NOT NULL,
	SAPAccountNumber int NOT NULL,
	ArrivalTime datetime2(0) NULL,
	IsEstimated bit NOT NULL,
	DNS bit NULL,
	ReportTimeLocal datetime2(0) NOT NULL,
	LastModifiedBy varchar(50) NOT NULL
	Constraint PK_StoreDeliveryTimeTrace Primary Key Clustered 
	(
		DeliveryDateUTC DESC,
		SAPAccountNumber ASC,
		ReportTimeLocal DESC
	)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table StoreDeliveryTimeTrace created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If TYPE_ID(N'APNSMerch.tKnownDeliveries') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpsertKnownDeliveries' and s.name = 'APNSMerch')
	Begin
		Drop proc APNSMerch.pUpsertKnownDeliveries
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc APNSMerch.pUpsertKnownDeliveries'
	End

	Drop Type APNSMerch.tKnownDeliveries
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* APNSMerch.tKnownDeliveries'
End
Go

Create Type APNSMerch.tKnownDeliveries AS TABLE(
	SAPAccountNumber int NOT NULL,
	KnownArrivalTime datetime2(0) NULL,
	KnownDNS bit Null,
	Primary Key Clustered
	(
		SAPAccountNumber ASC
	) WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type APNS.tNotificationItems created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from merchanidser service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpsertKnownDeliveries' and s.name = 'APNSMerch')
Begin
	Drop proc APNSMerch.pUpsertKnownDeliveries
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNSMerch.pUpsertKnownDeliveries'
End 
Go

Create proc APNSMerch.pUpsertKnownDeliveries
(
	@Known APNSMerch.tKnownDeliveries ReadOnly,
	@DeliveryDateUTC Date,
	@GSN varchar(50)
)
As
Begin
	Declare @ConfigValue varchar(4000)
	
	Select @ConfigValue = [Value]
	From Setup.Config Where ConfigID = 11

	Merge APNSMerch.DeliveryInfo t
	Using (
		Select @DeliveryDateUTC DeliveryDateUTC, @GSN GSN, k.SAPAccountNumber, KnownArrivalTime, KnownDNS 
		From @Known k
		Join SAP.Account a with (nolock) on k.SAPAccountNumber = a.SAPAccountNumber 
		Join SAP.Branch b with (nolock) on a.BranchID = b.BranchID
		Join dbo.udfSplit(@ConfigValue, ',') sp on b.SAPBranchID = sp.Value
		) s 
	On t.DeliveryDateUTC = s.DeliveryDateUTC And t.MerchandiserGSN = s.GSN And t.SAPAccountNumber = s.SAPAccountNumber
	When Matched Then Update
		Set t.KnownArrivalTime = s.KnownArrivalTime, t.KnownDNS = s.KnownDNS, t.LastModifiedBy = s.GSN, t.LastModified = SysDateTime()
	When Not Matched By Target Then
		Insert(DeliveryDateUTC, SAPAccountNumber, MerchandiserGSN, KnownArrivalTime, KnownDNS, isEstimated, LastModifiedBy, LastModified)
		Values(s.DeliveryDateUTC, s.SAPAccountNumber, s.GSN, s.KnownArrivalTime, s.KnownDNS, 0, s.GSN, SysDateTime());

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUpsertKnownDeliveries Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If TYPE_ID(N'APNSMerch.tDeliveries') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpdateDeliveries' and s.name = 'APNSMerch')
	Begin
		Drop proc APNSMerch.pUpdateDeliveries
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc APNSMerch.pUpdateDeliveries'
	End

	Drop Type APNSMerch.tDeliveries
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* APNSMerch.tDeliveries'
End
Go

CREATE TYPE APNSMerch.tDeliveries AS TABLE(
	DeliveryStopID int NULL,
	SAPAccountNumber varchar(20) NULL -- Reserved for the future for one less DB join
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type APNS.tDeliveries created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from driver delivery service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpdateDeliveries' and s.name = 'APNSMerch')
Begin
	Drop proc APNSMerch.pUpdateDeliveries
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNSMerch.pUpdateDeliveries'
End 
Go

Create proc APNSMerch.pUpdateDeliveries
(
	@Known APNSMerch.tDeliveries ReadOnly
)
As
Begin
	Declare @DeliveryInfo Table
	(
		DeliveryDateUTC date NOT NULL,
		SAPAccountNumber int NOT NULL,
		ArrivalTime datetime2(0) NULL,
		IsEstimated bit NOT NULL,
		DNS bit NULL,
		LastModifiedBy varchar(50) NOT NULL
	)

	-- The stop type other than STP will be filtred out by the field SAPAccountNumber
	Insert Into @DeliveryInfo
	Select ds.DeliveryDateUTC, 
		ds.SAPAccountNumber, 
		Coalesce(ds.ArrivalTime, ds.EstimatedArrivalTime, ds.PlannedArrival) ArrivalTime, 		
		Case When ds.ArrivalTime Is Null Then 1 Else 0 End IsEstimated,
		ds.DNS, 
		ds.LastModifiedBy
	From Mesh.DeliveryStop ds
	Where DeliveryStopID in (Select DeliveryStopID From @Known)
	And StopType = 'STP'
	And SAPAccountNumber is not null

	--Update DeliveryInfo
	Update t
	Set t.ArrivalTime = s.ArrivalTime, t.DNS = s.DNS, t.IsEstimated = s.IsEstimated, t.LastModifiedBy = s.LastModifiedBy, t.LastModified = SysDateTime() 
	From APNSMerch.DeliveryInfo t
	Join @DeliveryInfo s
	On t.DeliveryDateUTC = s.DeliveryDateUTC And t.SAPAccountNumber = s.SAPAccountNumber

	--Update Trace
	Insert Into APNSMerch.StoreDeliveryTimeTrace
        (DeliveryDateUTC
        ,SAPAccountNumber
        ,ArrivalTime
        ,IsEstimated
        ,DNS
		,LastModifiedBy
		,ReportTimeLocal
	)
	Select *, SYSDATETIME() From @DeliveryInfo

	--Get the Message
	Select 
	sm.DeliveryDateUTC,
	sm.SAPAccountNumber,
	p.GSN,
	--'[' + b.BranchName + ']' + 
	Case 
		When sm.DNS = 1 Then 'Delivery for ' 
		When sm.IsEstimated = 1 Then 'The new estimated delivery arrival for ' 
		Else 'Delivery for ' End 
	+
	--Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
	Concat(A.AccountName, ', ', A.Address, ', ', a.City, ' ')
	+
	Case When sm.DNS = 1 Then 'is canceled'  
		When sm.IsEstimated = 1 Then 'is ' 
		Else 'is arrived at ' End 
	+
	Case When sm.DNS = 1 Then '' 
		Else Ltrim(Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, sm.ArrivalTime), 100), 13, 100)) End Message
	From @DeliveryInfo ds
	Join APNSMerch.DeliveryInfo sm on sm.SAPAccountNumber = ds.SAPAccountNumber And ds.DeliveryDateUTC = sm.DeliveryDateUTC
	Join Setup.Merchandiser p on sm.MerchandiserGSN = p.GSN
	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	Join SAP.Branch b on a.BranchID = b.BranchID
	And (( Delta > 1800 ) Or ( Delta <> 0 And sm.IsEstimated = 0))

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUpdateDeliveries Created'
Go
