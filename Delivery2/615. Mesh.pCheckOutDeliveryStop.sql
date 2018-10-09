Use Merch
Go

If Exists (Select * From sys.procedures Where Name = 'pCheckOutDeliveryStop')
Begin
	Drop Proc Mesh.pCheckOutDeliveryStop
	Print '* Mesh.pCheckOutDeliveryStop'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
*/

Create Proc Mesh.pCheckOutDeliveryStop
(
	@CurrentDeliveryStopID int,
	@CheckOutTime DateTime2(0),
	@DepartureTime DateTime2(0) = null,
	@Voided Bit = 0,
	@CheckOutLatitude Decimal(10,6) = 0.0,
	@CheckOutLongitude Decimal(10,6) = 0.0,
	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(50),
	@LastModifiedUTC DateTime2(0)
)
As
	Set NoCount On;

	If @DepartureTime Is Null
		Set @DepartureTime = @CheckOutTime

	Update Mesh.DeliveryStop
	Set	
		CheckOutTime = @CheckOutTime
		,Voided = @Voided
		,DepartureTime = @DepartureTime
		,CheckOutLatitude = @CheckOutLatitude
		,CheckOutLongitude = @CheckOutLongitude
		,LastModifiedBy = @LastModifiedBy
		,LastModifiedUTC = @LastModifiedUTC
		,LocalUpdateTime = SysDateTime()
	Where DeliveryStopID = @CurrentDeliveryStopID
	And DNS = 0

	If (@Voided = 1)
	Begin
		Insert Mesh.DeliveryStop
				   (PlannedStopID
				   ,DeliveryDateUTC
				   ,RouteID
				   ,Sequence
				   ,StopType
				   ,SAPAccountNumber
				   ,IsAddedByDriver
				   ,Quantity
				   ,PlannedArrival
				   ,ServiceTime
				   ,TravelToTime
				   ,Voided
				   ,DNSReasonCode
				   ,DNSReason
				   ,EstimatedArrivalTime
				   ,CheckInTime
				   ,ArrivalTime
				   ,CheckInFarAwayReasonID
				   ,CheckInDistance
				   ,CheckInLatitude
				   ,CheckInLongitude
				   ,EstimatedDepartureTime
				   ,CheckOutTime
				   ,DepartureTime
				   ,CheckOutLatitude
				   ,CheckOutLongitude
				   ,LastModifiedBy
				   ,LastModifiedUTC
				   ,LocalUpdateTime)
		 Select PlannedStopID
				   ,DeliveryDateUTC
				   ,RouteID
				   ,Sequence * (-1)
				   ,StopType
				   ,SAPAccountNumber
				   ,IsAddedByDriver
				   ,Quantity
				   ,PlannedArrival
				   ,ServiceTime
				   ,TravelToTime
				   ,Voided
				   ,DNSReasonCode
				   ,DNSReason
				   ,EstimatedArrivalTime
				   ,CheckInTime
				   ,ArrivalTime
				   ,CheckInFarAwayReasonID
				   ,CheckInDistance
				   ,CheckInLatitude
				   ,CheckInLongitude
				   ,EstimatedDepartureTime
				   ,CheckOutTime
				   ,DepartureTime
				   ,CheckOutLatitude
				   ,CheckOutLongitude
				   ,LastModifiedBy
				   ,LastModifiedUTC
				   ,LocalUpdateTime
		From Mesh.DeliveryStop
		Where DeliveryStopID = @CurrentDeliveryStopID

		Update Mesh.DeliveryStop
		Set CheckInTime = null
			,ArrivalTime = null
			,CheckInFarAwayReasonID = null
			,CheckInDistance = null
			,CheckInLatitude = null
			,CheckInLongitude = null
			,CheckOutTime = null
			,DepartureTime = null
			,CheckOutLatitude = null
			,CheckOutLongitude = null
			,Voided = 0
		Where DeliveryStopID = @CurrentDeliveryStopID
	End

	exec Mesh.pUpdateEstimatedArrivals @Estimates = @Estimates, @LastModifiedBy = @LastModifiedBy, @LastModifiedUTC = @LastModifiedUTC	
Go

Print 'Mesh.pCheckOutDeliveryStop created'
Go

-----------------------------------
-----------------------------------

--Declare @Estimates Mesh.tEstimatedArrivals
--Declare @CurrentDate DateTime

--Insert Into @Estimates
--Values (
--577, 10, '2018-03-02 15:44:22')

--Insert Into @Estimates
--Values (
--583, 11, '2018-03-02 16:12:22')

--Insert Into @Estimates
--Values (
--580, 12, '2018-03-02 16:51:22')

--Set @CurrentDate = SysUTCDateTime()

--exec Mesh.pCheckOutDeliveryStop
--	@CurrentDeliveryStopID = 587,
--	@CheckOutTime = '2018-03-02 15:35:22',
--	@CheckOutLatitude = -94.098195,
--	@CheckOutLongitude =  45.639564, 
--	@Estimates = @Estimates, 
--	@LastModifiedBy = 'WUXYX002', 
--	@LastModifiedUTC = @CurrentDate

--Select *
--From Mesh.DeliveryStop
--Where DeliveryDateUTc = '2018-03-02'
--And RouteID = 100411011
--Order By Sequence 
--Go

