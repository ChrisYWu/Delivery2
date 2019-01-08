Use Merch
Go

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
	DepartureTime datetime2(0) NULL,
	KnownDepartureTime datetime2(0) NULL,
	IsEstimated bit NOT NULL,
	Delta As (datediff(second,KnownDepartureTime,DepartureTime)),
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
	DepartureTime datetime2(0) NULL,
	IsEstimated bit NOT NULL,
	DNS bit NULL,
	ReportTimeLocal datetime2(0) NOT NULL,
	LastModifiedBy varchar(50) NOT NULL,
	LastModified DateTime2(0) Not Null
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
	KnownDepartureTime datetime2(0) NULL,
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
	Merge APNSMerch.DeliveryInfo t
	Using (
		Select @DeliveryDateUTC DeliveryDateUTC, @GSN GSN, SAPAccountNumber, KnownDepartureTime, KnownDNS 
		From @Known) s 
	On t.DeliveryDateUTC = s.DeliveryDateUTC And t.MerchandiserGSN = s.GSN And t.SAPAccountNumber = s.SAPAccountNumber
	When Matched Then Update
		Set t.KnownDepartureTime = s.KnownDepartureTime, t.KnownDNS = s.KnownDNS, t.LastModifiedBy = s.GSN, t.LastModified = SysDateTime()
	When Not Matched By Target Then
		Insert(DeliveryDateUTC, SAPAccountNumber, MerchandiserGSN, KnownDepartureTime, KnownDNS, LastModifiedBy, LastModified)
		Values(s.DeliveryDateUTC, s.SAPAccountNumber, s.GSN, s.KnownDepartureTime, s.KnownDNS, s.GSN, SysDateTime());

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUpsertKnownDeliveries Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If TYPE_ID(N'APNSMerch.tDeliveries') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpsertDeliveries' and s.name = 'APNSMerch')
	Begin
		Drop proc APNSMerch.pUpsertDeliveries
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc APNSMerch.pUpsertDeliveries'
	End

	Drop Type APNSMerch.tDeliveries
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* APNSMerch.tDeliveries'
End
Go

CREATE TYPE APNSMerch.tDeliveries AS TABLE(
	SAPAccountNumber int NOT NULL,
	DepartureTime datetime2(0) NULL,
	IsEstimated bit NOT NULL,
	DNS bit Null,
	Primary Key Clustered
	(
		SAPAccountNumber ASC
	) WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type APNS.tDeliveries created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from driver delivery service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpsertDeliveries' and s.name = 'APNSMerch')
Begin
	Drop proc APNSMerch.pUpsertDeliveries
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNSMerch.pUpsertDeliveries'
End 
Go

Create proc APNSMerch.pUpsertDeliveries
(
	@Known APNSMerch.tDeliveries ReadOnly,
	@DeliveryDateUTC Date,
	@GSN varchar(50)
)
As
Begin
	--Update DeliveryInfo
	Update t
	Set t.DepartureTime = s.DepartureTime, t.DNS = s.DNS, t.IsEstimated = s.IsEstimated, t.LastModifiedBy = s.GSN, t.LastModified = SysDateTime() 
	From APNSMerch.DeliveryInfo t
	Join (
		Select @DeliveryDateUTC DeliveryDateUTC, @GSN GSN, SAPAccountNumber, DepartureTime, DNS, IsEstimated
		From @Known) s 
	On t.DeliveryDateUTC = s.DeliveryDateUTC And t.SAPAccountNumber = s.SAPAccountNumber

	--Update Trace
	Insert Into APNSMerch.StoreDeliveryTimeTrace
        (DeliveryDateUTC
        ,SAPAccountNumber
        ,DepartureTime
        ,IsEstimated
        ,DNS
        ,ReportTimeLocal)
	Select @DeliveryDateUTC DeliveryDateUTC, SAPAccountNumber, DepartureTime, IsEstimated, DNS, SysdateTime() 
	From @Known

	--Get the Message
	Select 
	p.PartyID,
	sm.SAPAccountNumber,
	DeliveryDateUTC,
	Phone, 
	--TimeZoneOffSet, 
	--a.AccountName, 
	--A.Address, 
	--A.City, 
	'[' + b.BranchName + ']' + 
	Case 
	When DNS = 1 Then 'The delivery for ' When IsEstimated = 1 Then 'The new estimated delivery for ' Else 'Delivery for ' End 
	--Case When IsEstimated = 1 Then '[Delay Notification:1 Hour Late Or More] The new estimated delivery for ' Else '[Delay Notification:1 Hour Late Or More] Delivery for ' End 
	+
	Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
	+
	Case When DNS = 1 Then 'is canceled'  When IsEstimated = 1 Then 'is ' Else 'is made at ' End 
	+
	Case When DNS = 1 Then '' Else Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, DepartureTime), 100), 13, 100) End MessageBody
	From Notify.StoreDeliveryMechandiser sm
	Join Notify.Party p on sm.PartyID = p.PartyID
	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	Join SAP.Branch b on a.BranchID = b.BranchID
	Where DeliveryDateUTC = Convert(Date, GetDate())
	And (( Delta < -1800 ) Or ( Delta <> 0 And IsEstimated = 0))

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUpsertDeliveries Created'
Go
