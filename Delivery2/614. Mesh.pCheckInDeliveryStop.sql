Use Merch
Go

If Exists (Select * From sys.procedures Where Name = 'pCheckInDeliveryStop')
Begin
	Drop Proc Mesh.pCheckInDeliveryStop
	Print '* Mesh.pCheckInDeliveryStop'
End 
Go

Print 'Mesh.tEstimatedArrivals created'
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Declare @Estimates Mesh.tEstimatedArrivals
Declare @CurrentDate DateTime

Insert Into @Estimates
Values (
577, 10, '2018-03-02 15:51:54')

Insert Into @Estimates
Values (
583, 11, '2018-03-02 16:19:48')

Insert Into @Estimates
Values (
580, 12, '2018-03-02 16:58:57')

Set @CurrentDate = SysUTCDateTime()

exec Mesh.pCheckInDeliveryStop
	@CurrentDeliveryStopID = 587,
	@CheckInTime = '2018-03-02 15:17:00',
	@ArrivalTime = null,
	@CheckInFarAwayReasonID = null,
	@CheckInDistance = '0.0567',
	@CheckInLatitude = -94.098234,
	@CheckInLongitude = 45.632581, 
	@Estimates = @Estimates, 
	@LastModifiedBy = 'WUXYX001', 
	@LastModifiedUTC = @CurrentDate

Select *
From Mesh.DeliveryStop
Where DeliveryDateUTc = '2018-03-02'
And RouteID = 100411011
Order By Sequence 
Go

*/

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
Go

Print 'Mesh.pCheckInDeliveryStop created'
Go

-----------------------------------
-----------------------------------


Declare @Estimates Mesh.tEstimatedArrivals
Declare @CurrentDate DateTime

Insert Into @Estimates
Values (
577, 10, '2018-03-02 15:51:54')

Insert Into @Estimates
Values (
583, 11, '2018-03-02 16:19:48')

Insert Into @Estimates
Values (
580, 12, '2018-03-02 16:58:57')

Set @CurrentDate = SysUTCDateTime()

exec Mesh.pCheckInDeliveryStop
	@CurrentDeliveryStopID = 587,
	@CheckInTime = '2018-03-02 15:17:00',
	@ArrivalTime = null,
	@CheckInFarAwayReasonID = null,
	@CheckInDistance = '0.0567',
	@CheckInLatitude = -94.098234,
	@CheckInLongitude = 45.632581, 
	@Estimates = @Estimates, 
	@LastModifiedBy = 'WUXYX001', 
	@LastModifiedUTC = @CurrentDate

Select *
From Mesh.DeliveryStop
Where DeliveryDateUTc = '2018-03-02'
And RouteID = 100411011
Order By Sequence 
Go

