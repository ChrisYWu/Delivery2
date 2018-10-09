USE [Merch]
GO

/****** Object:  StoredProcedure [Mesh].[pCopyCurrentIrvingApr12]    Script Date: 5/24/2018 11:09:05 AM ******/
DROP PROCEDURE [Mesh].[pCopyCurrent0522]
GO

/****** Object:  StoredProcedure [Mesh].[pCopyCurrentIrvingApr12]    Script Date: 5/24/2018 11:09:05 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Exec Mesh.pCopyCurrent0522 @AnchorDate = '2018-05-22', @Advance = 1, @HourOffset = 3, @RouteID = '102000463,102000938'
Go

Create Proc [Mesh].[pCopyCurrent0522]
(
	@AnchorDate Date = '2018-05-22',
	@Advance Int = 1,
	@HourOffset Int = 0,
	@RouteID varchar(3000) = null
)
As
	If @AnchorDate is Null
	Begin
		Set @AnchorDate = '2018-05-22'
	End

	Declare @TargetDate Date
	Set @TargetDate = DateAdd(Day, @Advance, Convert(Date, GetDate()))
	Declare @OffSetDays Int 
	Select @OffSetDays = DateDiff(Day, @AnchorDate, @TargetDate)

	Declare @RouteIDs Table
	(
		RouteID int
	)

	If Coalesce(RTrim(LTrim(@RouteID)), '') = ''
	Begin
		SEt @RouteID = '102000463,102000938,100521528,108300759,108000502'
	End

	Insert Into @RouteIDs
	Select Value From dbo.Split(@RouteID, ',')

	Delete 
	From Mesh.PlannedStop
	Where 
	DeliveryDateUTC = @TargetDate
	And
	RouteID In
	(
		Select @RouteID From @RouteIDs
	)

	Delete 
	From Mesh.DeliveryRoute
	Where 
	DeliveryDateUTC = @TargetDate
	And
	RouteID In
	(
		Select @RouteID From @RouteIDs
	)

	Insert Into Mesh.DeliveryRoute
			(PKEY
			,DeliveryDateUTC
			,RouteID
			,TotalQuantity
			,PlannedStartTime
			,SAPBranchID
			,FirstName
			,Lastname
			,PhoneNumber
			,PlannedCompleteTime
			,PlannedTravelTime
			,PlannedServiceTime
			,PlannedBreakTime
			,PlannedPreRouteTime
			,PlannedPostRouteTime
			,LastModifiedBy
			,LastModifiedUTC
			,LocalSyncTime
			,OrderCountLastUpdatedLocalTime)
	Select PKEY - Convert(int, Rand() * 10000000) - DATEPART(Month, @TargetDate)*100 - DATEPART(Day, @TargetDate) PKEY
			,@TargetDate
			,RouteID
			,TotalQuantity
			,DateAdd(Hour, @HourOffset, DateAdd(Day, @OffSetDays, PlannedStartTime))
			,SAPBranchID
			,FirstName
			,Lastname
			,PhoneNumber
			,DateAdd(Hour, @HourOffset, DateAdd(Day, @OffSetDays, PlannedCompleteTime))
			,PlannedTravelTime
			,PlannedServiceTime
			,PlannedBreakTime
			,PlannedPreRouteTime
			,PlannedPostRouteTime
			,LastModifiedBy
			,LastModifiedUTC
			,LocalSyncTime
			,OrderCountLastUpdatedLocalTime
	From Mesh.DeliveryRoute
	Where DeliveryDateUTC = @AnchorDate
	And RouteID In
	(
		Select @RouteID From @RouteIDs
	)

	Insert Into Mesh.PlannedStop(
		DeliveryRouteID, 
		Pkey, 
		DeliveryDateUTC, 
		RouteID, 
		Sequence, 
		StopType, 
		SAPAccountNumber, 
		PlannedArrival, 
		TravelToTime, 
		ServiceTime, 
		LastModifiedBy, 
		LastModifiedUTC, 
		LocalSyncTime
	)
	Select a.DeliveryRouteID, b.*
	From 
	(
		Select *
		From Mesh.DeliveryRoute dr
		Where dr.DeliveryDateUTC = @TargetDate
		And RouteID In
		(
			Select @RouteID From @RouteIDs
		)
	) a
	Join
	(
		Select 
			ds.Pkey - 10000000 Pkey, 
			@TargetDate DeliveryDateUTC, 
			ds.RouteID, 
			Sequence, 
			StopType, 
			SAPAccountNumber, 
			DateAdd(Hour, @HourOffset, DateAdd(Day, @OffSetDays, PlannedArrival)) PlannedArrival, 
			TravelToTime, 
			ServiceTime, 
			ds.LastModifiedBy, 
			ds.LastModifiedUTC, 
			ds.LocalSyncTime 
		From Mesh.DeliveryRoute dr
		Join Mesh.PlannedStop ds on dr.DeliveryDateUTC = ds.DeliveryDateUTC And dr.RouteID = ds.RouteID
		Where dr.DeliveryDateUTC = @AnchorDate
		And dr.RouteID In
		(
			Select @RouteID From @RouteIDs
		)
	) b on a.DeliveryDateUTC = b.DeliveryDateUTC And a.RouteID = b.RouteID


GO

