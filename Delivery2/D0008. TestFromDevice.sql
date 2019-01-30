use Merch
Go

Select *
From Setup.Merchandiser
Where GSN = 'ADEAX015'--'WUXYX001'

Select *
From APNS.App

Select *
From APNS.Cert

Select *
From APNS.AppUserToken


Update Mesh.DeliveryStop
Set DeliveryDateUTC = DateAdd(Day, DateDiff(day, DeliveryDateUTC, GetDate()), DeliveryDateUTC), 
PlannedArrival = DateAdd(Day, DateDiff(day, PlannedArrival, GetDate()), PlannedArrival),
EstimatedArrivalTime = DateAdd(Day, DateDiff(day, EstimatedArrivalTime, GetDate()), EstimatedArrivalTime),
EstimatedDepartureTime = DateAdd(Day, DateDiff(day, EstimatedDepartureTime, GetDate()), EstimatedDepartureTime),
CheckInTime = null,
CheckInLatitude = null,
CheckInLongitude = null,
CheckInFarAwayReasonID = null,
CheckInDistance = Null,
ArrivalTime = null
Where DeliveryStopID = 66474

Select *
From Mesh.DeliveryStop
Where DeliveryStopID = 66474


Select Top 50 *
From Setup.WebAPILog
Order By LogID Desc

Select *
From Mesh.DeliveryStop
Where DeliveryStopID = 66474

Select *
From APNS.NotificationQueue

Update APNS.NotificationQueue
Set LockerID = null, LockDate = null
Where ItemID in (18, 19)

Update APNS.NotificationQueue
Set EnqueueDate = DateAdd(MINUTE, 1, EnqueueDate), DeliveredDate=DATEADD(Minute, 1, DeliveredDate)
Where ItemID = 17

exec  APNS.pGetMessagesForNotification @LockerID='00', @Debug=1
Select * From APNS.NotificationQueue Where ItemID = 17

Delete 
From APNS.NotificationQueue
Where itemID > 13

Update APNS.NotificationQueue
Set DeliveredDate=DATEADD(Minute, 6, DeliveredDate)
Where ItemID = 17


--Delete APNS.NotificationQueue
--Where ItemID > 11

--Delete
--From APNSMerch.DeliveryInfo
--Where DeliveryDateUTC = '2019-01-23' And MerchandiserGSN = 'ADEAX015'

Select *
From Mesh.DeliveryStop
Where DeliveryStopID = 66474

Select DateDiff(HOUR, '2019-1-18', GetDAte())


Declare @T APNSMerch.tKnownDeliveries 
Insert @T Values(11321447, '2019-01-24 14:09:06', 0)

exec APNSMerch.pUpsertKnownDeliveries @Known = @T, @DeliveryDateUTC = '2019-01-24', @GSN = 'WUXYX001'

Select *
From APNSMerch.DeliveryInfo
Where MerchandiserGSN = 'ADEAX015'

Select *, DATEDIFF(s, KnownArrivalTime, ArrivalTime)
From APNSMerch.DeliveryInfo
Where MerchandiserGSN = 'ADEAX015'


Select * From APNS.NotificationQueue



Select *
From APNS.NotificationQueue

Select *
From APNSMerch.DeliveryInfo

Update APNS.NotificationQueue
Set Message = 'Hello, World!'
Where ItemID = 11


exec  APNS.pGetMessagesForNotification @LockerID='00', @Debug=1

Delete From APNS.NotificationQueue

Update APNS.NotificationQueue
Set LockDate = null, LockerID = null


Declare	@LockerID varchar(50); Set @LockerID = '--'
Declare @DelayThreshold int = 60;
Declare @LonerThreshhold int = 240;
Declare @Debug bit = 0

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
	Left Join APNS.AppUserToken t on q.GSN = t.GSN
	Where LockerID = @LockerID And LockDate = @LockDate
	Order By ItemID

	Select *
	From APNS.AppUserToken

	Select Top 100 *
	From Setup.WebAPILog
	Order by LogId Desc

Select *, Len(P12)
From APNS.Cert

Select *
Into APNS.AppBK
From APNS.App

Select *, Len(P12)
From APNS.Cert

Update APNS.AppUserToken
SEt Token = '07fe4f023fe8a573648669f7ab7815189c7d8a2b23f71b3e52c4034bfb3ae12b'
Where GSN = 'WUXYX001'

'8680a86f532c29feeb249453286241b3f8f0a7f68a1bec2a718837c9220c81a8'
'07fe4f023fe8a573648669f7ab7815189c7d8a2b23f71b3e52c4034bfb3ae12b'

Select *
From APNS.AppUserToken

Select *
From APNS.AppUserTokenBK

Update APNS.AppUserToken
SEt Token = '8680a86f532c29feeb249453286241b3f8f0a7f68a1bec2a718837c9220c81a8'
Where GSN = 'ADEAX015'

Declare @P Varbinary(max)
Select @P = P12
From BSCCAP108.Merch.APNS.Cert
Where CertID = 5


Update APNS.Cert
Set P12 = @P
Where CertID = 2


Select *, len(P12)
From APNS.Cert

Alter Table APNS.Cert
Add P12Len as Len(P12)


Select *
From APNS.Cert


Select *, Len(P12)
From BSCCAP108.Merch.APNS.Cert
--Where AppID = 2 And CertID = 3

Select *
From Merch.Setup.Merchandiser
Where GSN in 
(
	Select GSN
	From APNS.AppUserToken
)

Select *
From APNS.AppUserToken


Select *
From APNS.App

'dd6299e259ef3ea8eb9bf761976f2fa927aa8fd4deb596f7db5d7eb74ac22b5d'

2665aea92c99e48b86efee1f84ba2a0d0d5b08de59fa18bac27656fc9b146cab

20d8d026c800d66f1a0a145a1db96d562dd6d24103bb4793fb4dd829b0516b7c

6b87ec7a3e9263e92d4b2366db874bef5a037fb67b45ff25685189e326e70b70

Delete
From Setup.ProfileImage
Where GSN = 'WUXYX001'

Delete
From Operation.AzureBlobStorage
Where BlobID = 9191

