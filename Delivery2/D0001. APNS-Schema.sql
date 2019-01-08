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
	AppName varchar(128) not null,
	CONSTRAINT PK_App PRIMARY KEY CLUSTERED 
	(
		AppID ASC
	)
)
Go
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Table APNS.App created'
Go

Insert APNS.App(AppName)
Values('Merchandiser MyDay')
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
	LastModified DateTime,
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

	Insert APNS.Cert(AppID, CertType, P12, LastModified)
	Select AppID, CertType, P12, LastModified From BSCCAP108.Merch.APNS.Cert
End
Else
Begin
	Insert APNS.Cert(AppID, CertType, P12, LastModified)
	Select 1, 'Sandbox', BulkColumn, SysDateTime() From OpenRowSet(Bulk N'\\BSCCAP108\Test\APNSTest2Certificate.p12', SINGLE_BLOB) As Document
End
Go

Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Sandbox Cert Inserted'
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
	@AppID int, 
	@GSN varchar(20),
	@Token varchar(max)
)
As
Begin
	Declare @AppUserTokenID Int
	
	Select @AppUserTokenID = Token From APNS.AppUserToken Where AppID = @AppID And @GSN = GSN

	If @AppUserTokenID is null 
	Begin
		Insert APNS.AppUserToken(AppID, GSN, Token, LastModified)
		Values(@AppID, @GSN, @Token, SysDateTime())
	End
	Else
	Begin
		Update APNS.AppUserToken
		Set @Token = Token, LastModified = SysDateTime()
		Where AppUserTokenID = @AppUserTokenID
	End
End
Go

--exec APNS.pUpsertAppTokenForUser @AppID =1, @GSN= 'WUXYX001', @Token='07fe4f023fe8a573648669f7ab7815189c7d8a2b23f71b3e52c4034bfb3ae12b'
Print @@ServerName + '/' + DB_Name() + ':' + Convert(varchar, SysDateTime(), 120) + '> '
+  'Proc APNS.pUpsertAppTokenForUser Created'
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

Create proc APNS.pGetMessagesForNotification
(
	@LockerID varchar(50),
	@DelayThreshold int = 60,
	@LonerThreshhold int = 240
)
As
Begin
	Declare @Lastest DateTime2(0)
	Select @Lastest = Max(EnqueueDate)
	From APNS.NotificationQueue
	Where LockerID is Null

	Declare @LastestSent DateTime2(0)
	Select @LastestSent = Max(DeliveredDate)
	From APNS.NotificationQueue
	Where LockerID is Not Null

	Declare @LockDate DateTime2(3)
	Select @LockDate = Convert(DateTime2(3), SysDateTime())

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

	Select ItemID, GSN, Message, MessageType, SubjectIdentifier
	From APNS.NotificationQueue
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
