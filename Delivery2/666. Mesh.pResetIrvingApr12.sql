Use Merch
Go

Drop Proc Mesh.pResetIrvingApr12
Go

Create Proc Mesh.pResetIrvingApr12
As
  Update Mesh.DeliveryRoute
  Set ActualStartTime = null,
  ActualCompleteTime = null,
  ActualStartFirstName = null,
  ActualStartGSN = null,
  ActualStartLastName = null, 
  ActualStartPhoneNumber = null,
  ActualStartLongitude = null,
  ActualStartLatitude = null
  Where DeliveryDateUTC = Convert(Date, GetDate())

  Delete
  From Mesh.DeliveryStop
  Where DeliveryDateUTC = Convert(Date, GetDate())

  Delete 
  From Mesh.Resequence
  Where DeliveryDateUTC = Convert(Date, GetDate())
  --- Will cascade delete Mesh.ResequenceDetail
  --- Will cascade delete Mesh.ResequeceReasons as well
Go

Drop Proc Mesh.pCopyCurrentIrvingApr12
Go

Create Proc Mesh.pCopyCurrentIrvingApr12
(
	@Advance Int = 1,
	@HourOffset Int = 0,
	@RouteID int = 111501301
)
As

Declare @TargetDate Date
Set @TargetDate = DateAdd(Day, @Advance, Convert(Date, GetDate()))
Declare @OffSetDays Int 
Select @OffSetDays = DateDiff(Day, '2018-04-12', @TargetDate)

	Delete 
	From Mesh.PlannedStop
	Where 
	DeliveryDateUTC = @TargetDate
	And
	RouteID In
		(
		@RouteID
			--111501301
			--,111501302
			--,111501303
			--,111501304
		)

	Delete 
	From Mesh.DeliveryRoute
	Where 
	DeliveryDateUTC = @TargetDate
	And
	RouteID In
		(
		@RouteID
			--111501301
			--,111501302
			--,111501303
			--,111501304
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
	Where DeliveryDateUTC = '4-12-2018'
	And RouteID In
		(
		@RouteID
			--111501301
			--,111501302
			--,111501303
			--,111501304
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
		And dr.RouteID In
				(
				@RouteID
					--111501301
					--,111501302
					--,111501303
					--,111501304
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
		Where dr.DeliveryDateUTC = '4-12-2018'
		And dr.RouteID In
				(
					111501301
					,111501302
					,111501303
					,111501304
				)
	) b on a.DeliveryDateUTC = b.DeliveryDateUTC And a.RouteID = b.RouteID

Go

Exec Mesh.pCopyCurrentIrvingApr12 0, 5, 111501304
Go
