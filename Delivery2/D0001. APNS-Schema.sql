Use Merch
Go

Set NoCount On
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Not Exists (Select * From sys.schemas Where Name = 'APNS')
Begin
	exec('Create Schema APNS')
End
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'App' and s.name = 'APNS')
Begin
	If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Cert' and s.name = 'APNS')
	Begin
		Drop Table APNS.Cert
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping table APNS.Cert'
	End

	If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'AppUserToken' and s.name = 'APNS')
	Begin
		Drop Table APNS.AppUserToken
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping table APNS.AppUserToken'
	End

	Drop Table APNS.App
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table APNS.App'
End
Go

Create Table APNS.App
( 
	AppID int not null identity(1,1),
	BundleID varchar(128) not null,
	CONSTRAINT PK_App PRIMARY KEY CLUSTERED 
	(
		AppID ASC
	)
)
Go
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table APNS.App created'
Go

Insert APNS.App(BundleID)
Values('com.dpsg.internal.MerchMyDayTest')
Go
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Merchandiser MyDay inserted into APNS.app'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'Cert' and s.name = 'APNS')
Begin
	Drop Table APNS.Cert
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table APNS.Cert'
End
Go

Create Table APNS.Cert
(
	CertID int not null identity(1,1),
	AppID int,
	CertType varchar(20),
	P12 varbinary(max),
	P12Len as Len(P12),
	ExpirationDate DateTime2(0),
	LastModified DateTime2(0),
	CONSTRAINT PK_Cert PRIMARY KEY CLUSTERED 
	(
		CertID ASC
	)
)
Go

Alter Table APNS.Cert With Check Add Constraint FK_Cert_App Foreign Key(AppID)
References APNS.App (AppID)
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table APNS.Cert created'
Go

If @@ServerName = 'BSCCSQ07' 
Begin
	/* Make sure a local folder is created to contain the file of p12 and a network share is created 
		that gives everyone in domain full control and every local user full control
	   Example for testing
	Select BulkColumn From OpenRowSet(Bulk N'\\BSCCAP108\Test\APNSTest2Certificate.p12', SINGLE_BLOB) As Document
	Select BulkColumn From OpenRowSet(Bulk N'\\BSCCAP108\Test\test.txt', SINGLE_CLOB) As Document
	*/

	Insert APNS.Cert(AppID, CertType, P12, ExpirationDate, LastModified)
	Select AppID, CertType, P12, ExpirationDate, LastModified From BSCCAP108.Merch.APNS.Cert
End
Else
Begin
	Insert APNS.Cert(AppID, CertType, P12, ExpirationDate, LastModified)
--	Select 1, 'SandboxB', BulkColumn, '2020-01-17 9:54:43', SysDateTime() From OpenRowSet(Bulk N'\\BSCCAP108\Test\Sandbox-p12-B.p12', SINGLE_BLOB) As Document
	
	Select 1, 'Sandbox', BulkColumn, '2020-01-17 9:54:43', SysDateTime() From OpenRowSet(Bulk N'\\BSCCAP108\Test\MerchMyDayTest-Dev.p12', SINGLE_BLOB) As Document
	Union
	Select 1, 'Prod', BulkColumn, '2020-02-16 10:01:34', SysDateTime() From OpenRowSet(Bulk N'\\BSCCAP108\Test\MerchMyDayTest-Prod.p12', SINGLE_BLOB) As Document

End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Sandbox/Prod Cert Inserted'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-- Caller is driver service --
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetCertForApp' and s.name = 'APNS')
Begin
	Drop proc APNS.pGetCertForApp
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pGetCertForApp'
End 
Go

Create proc APNS.pGetCertForApp
(
	@AppID int, 
	@CertType varchar(20)
)
As
Begin
	Select Top 1 P12 From APNS.Cert Where AppID = @AppID And @CertType = CertType
End
Go

--exec APNS.pGetCertForApp @AppID =1, @CertType= 'SandBox'
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pGetCertForApp Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'AppUserToken' and s.name = 'APNS')
Begin
	Drop Table APNS.AppUserToken
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table APNS.AppUserToken'
End
Go

Create Table APNS.AppUserToken
(
	AppUserTokenID int not null identity(1,1),
	AppID int,
	GSN varchar(50),
	Token varchar(max), -- Apple Push Notification Service Programming guide very clearly says: "Important: APNs device tokens are of variable length. Do not hardcode their size. https://developer.apple.com/library/mac/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/Chapters/Introduction.html"
	LastModified DateTime,
	Constraint PK_AppUserToken Primary Key Clustered 
	(
		AppUserTokenID ASC
	)
)
Go

Alter Table APNS.AppUserToken with Check Add Constraint FK_AppUserToken_App FOREIGN KEY(AppID)
References APNS.App (AppID)
On Delete Cascade
Go

ALTER TABLE APNS.AppUserToken CHECK CONSTRAINT FK_AppUserToken_App
GO

Create Unique NonClustered Index UNCI_AppToken_AppID_GSN ON APNS.AppUserToken
(
	GSN ASC,
	AppID ASC
) Include (Token) 
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table APNS.AppUserToken created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-- Caller is Merchandiser service --
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUpsertAppTokenForUser' and s.name = 'APNS')
Begin
	Drop proc APNS.pUpsertAppTokenForUser
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pUpsertAppTokenForUser'
End 
Go

Create proc APNS.pUpsertAppTokenForUser
(
	@BundleID varchar(128), 
	@GSN varchar(20),
	@Token varchar(max)
)
As
Begin
	Declare @AppID int

	Select @AppID = AppID
	From APNS.App
	Where BundleID = @BundleID

	If @AppID is null
	Begin
		Insert APNS.App(BundleID) Values (@BundleID)
		Select @AppID = SCOPE_IDENTITY()
	End

	Declare @AppUserTokenID Int
	
	Select @AppUserTokenID = AppUserTokenID From APNS.AppUserToken Where AppID = @AppID And @GSN = GSN

	If @AppUserTokenID is null 
	Begin
		Insert APNS.AppUserToken(AppID, GSN, Token, LastModified)
		Values(@AppID, Upper(@GSN), @Token, SysDateTime())
	End
	Else
	Begin
		Update APNS.AppUserToken
		Set Token = @Token, LastModified = SysDateTime()
		Where AppUserTokenID = @AppUserTokenID
	End

	Delete APNS.AppUserToken
	Where Token = @Token
	And GSN != @GSN
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUpsertAppTokenForUser created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
If Exists (Select * From sys.tables t Join sys.schemas s on t.schema_id = s.schema_id Where t.name = 'NotificationQueue' and s.name = 'APNS')
Begin
	Drop Table APNS.NotificationQueue
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping table APNS.NotificationQueue'
End
Go

CREATE TABLE APNS.NotificationQueue (
	ItemID bigint IDENTITY(1,1) NOT NULL,
	GSN varchar(50) NOT NULL,
	Message nvarchar(2048) NOT NULL,
	MessageType varchar(128) NOT NULL,
	LockerID varchar(50) NULL,
	SubjectIdentifier varchar(50) NOT NULL,
	EnqueueDate datetime2(0) NOT NULL,
	LockDate datetime2(3) NULL,
	DeliveredDate datetime2(0) NULL,
	Constraint PK_NotificationQueue Primary Key Clustered 
	(
		ItemID Desc
	)
)
Go

ALTER TABLE APNS.NotificationQueue  WITH CHECK ADD  CONSTRAINT CK_NotificationQueue CHECK  ((MessageType='MerchandiserDeliveryUpdate'))
Go

ALTER TABLE APNS.NotificationQueue CHECK CONSTRAINT CK_NotificationQueue
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table APNS.NotificationQueue created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
IF TYPE_ID(N'APNS.tDeliveryMessage') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pEnqueueDeliveryMessages' and s.name = 'APNS')
	Begin
		Drop proc APNS.pEnqueueDeliveryMessages
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc APNS.pEnqueueDeliveryMessages'
	End

	Drop Type APNS.tDeliveryMessage
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* APNS.tDeliveryMessage'
End
GO

CREATE TYPE APNS.tDeliveryMessage AS TABLE(
	GSN varchar(20) not null,
	Message nvarchar(2048) not null,
	SAPAccountNumber varchar(50) not null
	PRIMARY KEY CLUSTERED 
	(
		GSN ASC, SAPAccountNumber ASC
	)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type APNS.tDeliveryMessage created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from driver service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pEnqueueDeliveryMessages' and s.name = 'APNS')
Begin
	Drop proc APNS.pEnqueueDeliveryMessages
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pEnqueueDeliveryMessages'
End 
Go

Create proc APNS.pEnqueueDeliveryMessages
(
	@Items APNS.tDeliveryMessage ReadOnly
)
As
Begin
	Insert Into APNS.NotificationQueue(GSN, Message, MessageType, SubjectIdentifier, EnqueueDate)
	Select GSN, Message, 'MerchandiserDeliveryUpdate', SAPAccountNumber, SysDateTime()
	From @Items
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pEnqueueDeliveryMessages Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
-- Caller is driver service ---
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pEnqueueMessage' and s.name = 'APNS')
Begin
	Drop proc APNS.pEnqueueMessage
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pEnqueueMessage'
End 
Go

Create proc APNS.pEnqueueMessage
(
	@GSN varchar(20),
	@Message nvarchar(2048),
	@MessageType varchar(50),
	@SubjectIdentifier varchar(50)
)
As
Begin
	Insert Into APNS.NotificationQueue(GSN, Message, MessageType, SubjectIdentifier, EnqueueDate)
	Values (@GSN, @Message, @MessageType, @SubjectIdentifier, SysDateTime())
End
Go

--exec APNS.pUpsertAppTokenForUser @AppID =1, @GSN= 'WUXYX001', @Token='07fe4f023fe8a573648669f7ab7815189c7d8a2b23f71b3e52c4034bfb3ae12b'
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pEnqueueMessage Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from driver service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pGetMessagesForNotification' and s.name = 'APNS')
Begin
	Drop proc APNS.pGetMessagesForNotification
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pGetMessagesForNotification'
End 
Go

--exec  APNS.pGetMessagesForNotification @LockerID='00', @Debug=1

Create proc APNS.pGetMessagesForNotification
(
	@LockerID varchar(50),
	@DelayThreshold int = 60,
	@LonerThreshhold int = 240,
	@Debug bit = 0
)
As
Begin
	Declare @Lastest DateTime2(0)
	Select @Lastest = Max(IsNull(EnqueueDate, '2000-01-01'))
	From APNS.NotificationQueue
	Where LockerID is Null

	Declare @LastestSent DateTime2(0)
	Select @LastestSent = IsNull(Max(IsNull(DeliveredDate, '2000-01-01')), '2000-01-01')
	From APNS.NotificationQueue
	Where LockerID is Not Null

	Declare @LockDate DateTime2(3)
	Select @LockDate = Convert(DateTime2(3), SysDateTime())

	If (@Debug = 1) 
	Begin
		Select @Lastest Lastest, @LastestSent LastestSent, @LockDate LockDate, @LockerID LockerID  
	End

	Update APNS.NotificationQueue
	Set LockerID = @LockerID, LockDate = @LockDate 
	Where 
	(
		(DateDiff(s, @Lastest, SysDateTime()) > @DelayThreshold)
			Or
		(DateDiff(s, @LastestSent, SysDateTime()) > @LonerThreshhold)
	)
	And LockerID is null
	And DateDiff(s, EnqueueDate, SysDateTime()) < 86400   --Only interested in notifications within a day

	Select ItemID, Message, Token
	From APNS.NotificationQueue q
	Join APNS.AppUserToken t on q.GSN = t.GSN
	Where LockerID = @LockerID And LockDate = @LockDate
	Order By ItemID
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pGetMessagesForNotification Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
IF TYPE_ID(N'APNS.tNotificationItems') IS Not NULL
Begin
	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUnlockItems' and s.name = 'APNS')
	Begin
		Drop proc APNS.pUnlockItems
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc APNS.pUnlockItems'
	End

	If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pSetMessagesDelivered' and s.name = 'APNS')
	Begin
		Drop proc APNS.pSetMessagesDelivered
		Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
		+  '* Dropping proc APNS.pSetMessagesDelivered'
	End

	Drop Type APNS.tNotificationItems
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+ '* APNS.tNotificationItems'
End
GO

CREATE TYPE APNS.tNotificationItems AS TABLE(
	ItemID bigint NOT NULL
	PRIMARY KEY CLUSTERED 
(
	ItemID ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+ 'Type APNS.tNotificationItems created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from driver service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pUnlockItems' and s.name = 'APNS')
Begin
	Drop proc APNS.pUnlockItems
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pUnlockItems'
End 
Go

Create proc APNS.pUnlockItems
(
	@Items APNS.tNotificationItems readonly
)
As
Begin
	Set Nocount On

	Update APNS.NotificationQueue
	Set LockerID = null, LockDate = null, DeliveredDate = null
	Where ItemID In (Select ItemID From @Items)
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUnlockItems Created'
Go

--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
/* This is called from driver service */
If Exists (Select * From sys.procedures p join sys.schemas s on p.schema_id = s.schema_id and p.name = 'pSetMessagesDelivered' and s.name = 'APNS')
Begin
	Drop proc APNS.pSetMessagesDelivered
	Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
	+  '* Dropping proc APNS.pSetMessagesDelivered'
End 
Go

Create proc APNS.pSetMessagesDelivered
(
	@Items APNS.tNotificationItems ReadOnly
)
As
Begin
	Update APNS.NotificationQueue
	Set DeliveredDate = SysDateTime()
	Where ItemID in (Select ItemID From @Items)
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pSetMessagesDelivered Created'
Go

--Declare @Its APNS.tNotificationItems
--Insert @Its Values(7)
--Insert @Its Values(8)
--Insert @Its Values(9)

--exec APNS.pUnlockItems @Items = @Its
--Select * From APNS.NotificationQueue


