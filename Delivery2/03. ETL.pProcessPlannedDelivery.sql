use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('ETL.pProcessPlannedDelivery'))
Begin
	Drop Proc ETL.pProcessPlannedDelivery
	Print '* ETL.pProcessPlannedDelivery'
End
Go

/*
Exec ETL.pProcessPlannedDelivery


*/

Create Proc ETL.pProcessPlannedDelivery
AS
	Set NoCount On;
	--- Set StopSequence through self-join
	Update t
	Set t.StopSequence = s.StopSequence
	From Operation.DeliveryPlan t
	Join
	(Select DeliveryDate, RNKey, RouteNumber, DriverID, PlannedArrivalTime, Row_Number() Over (Partition by DeliveryDate, RNKey, RouteNumber, DriverID Order By PlannedArrivalTime) StopSequence
	From Operation.DeliveryPlan) s on s.DeliveryDate = t.DeliveryDate And t.RNKey = s.RNKey And s.RouteNumber = t.RouteNumber And s.DriverID = t.DriverID And s.PlannedArrivalTime = t.PlannedArrivalTime

	--- Derive ProjectedDepartureTime
	Update Operation.DeliveryPlan 
	Set ProjectedDepartureTime = DateAdd(Second, PlannedServiceTimeInSec, PlannedArrivalTime)

	--- Derive ProjectedArrivalTimeWithoutBreak through self-join
	Update t Set ProjectedArrivalTimeWithoutBreak = DateAdd(Second, t.PlannedTravelTimeInSec, s.ProjectedDepartureTime) 
	From Operation.DeliveryPlan t
	Join
	(
		Select DeliveryDate, RouteNumber, DriverID, StopSequence + 1 StopSequence, ProjectedDepartureTime
		From Operation.DeliveryPlan 
	) s on t.DeliveryDate = s.DeliveryDate And t.RouteNumber = s.RouteNumber And t.StopSequence = s.StopSequence And t.DriverID = s.DriverID
	Where StopType Not Like '3%'

	--- Fill in Runtime since initial branch arrival
	Update s
	Set RunTimeAtArrivalSinceInitialArrivalInSec = DateDiff(Second, t.PlannedArrivalTime, s.ProjectedArrivalTimeWithoutBreak)
	From Operation.DeliveryPlan t
	Join Operation.DeliveryPlan s on t.DeliveryDate = s.DeliveryDate And t.RouteNumber = s.RouteNumber And t.DriverID = s.DriverID And t.StopType Like '1%' And s.StopType Like '2%'

	--- Fill in Runtime from Departure since initial branch arrival
	Update t
	Set RunTimeAtDepartureSinceInitialArrivalInSec = RunTimeAtArrivalSinceInitialArrivalInSec + PlannedServiceTimeInSec
	From Operation.DeliveryPlan t

	--- Calculate ProjectedBreakTimeInSec
	Update Operation.DeliveryPlan
	Set ProjectedBreakTimeInSec = DateDiff(Second, ProjectedArrivalTimeWithoutBreak, PlannedArrivalTime)

	--- The Break after departure for whole hour rule(break after leaving a work site)
	Update Operation.DeliveryPlan
	Set PotentialBreakGivenAtWholeHourBeforeArrival = RunTimeAtArrivalSinceInitialArrivalInSec / 3600
	Where ProjectedBreakTimeInSec > 0

	--- The Break after arrival for whole hour rule(break during work at the work site)
	Update Operation.DeliveryPlan Set PotentialBreakGivenAtWholeHourBeforePreviousDeparture = Null

	Update d
	Set d.PotentialBreakGivenAtWholeHourBeforePreviousDeparture = p.RunTimeAtDepartureSinceInitialArrivalInSec / 3600
	From Operation.DeliveryPlan d
	Join Operation.DeliveryPlan p 
		On d.ProjectedBreakTimeInSec > 0 
			And d.DeliveryDate = p.DeliveryDate 
			And d.RNKey = p.RNKey 
			And d.RouteNumber = p.RouteNumber 
			And d.DriverID = p.DriverID 
			And d.StopSequence = p.StopSequence + 1

	-------------------------------------------
	-------------------------------------------
	-------------------------------------------
	-------------------------------------------

	Declare @DeliveryDate Date
	Select Top 1 @DeliveryDate = DeliveryDate
	From Operation.DeliveryPlan

	If Exists (Select * From Operation.Delivery
			Where DeliveryDate = @DeliveryDate)
		Return
	-------------------------------------------

	----------------- 
	----------------- 
	Declare @D Table
	(
		DeliveryDate Date,
		RouteNumber varchar(20),
		SalesOfficeID int,
		DriverID varchar(20),
		StopType varchar(20),
		StopID int,
		StopSequence int,
		PlannedArrivalTimeUTC datetime2(0),
		PlannedServiceTimeInSec int,
		PlannedDrivingTimeInSec int
	)

	---Creating Delivery Table
	--1. Split route, or route with more than 1 DriverID is eleminated
	--2. Latest Route Session taken if there are more than 1 session
	--3. Breaktime added
	Insert Into @D
	Select p.DeliveryDate, p.RouteNumber, SalesOfficeID, DriverID, StopType, StopID, StopSequence, PlannedArrivalTime PlannedArrivalTimeUTC, PlannedServiceTimeInSec, PlannedTravelTimeInSec
	From Operation.DeliveryPlan p
		Join 
		(
			Select DeliveryDate, RouteNumber, Max(RNKey) RNKey
			From Operation.DeliveryPlan
			Group By DeliveryDate, RouteNumber
			Having Count(Distinct DriverID) = 1
		) S on p.DeliveryDate = S.DeliveryDate And p.RouteNumber = S.RouteNumber And p.RNKey = S.RNKey
	Union
	Select p.DeliveryDate, p.RouteNumber, SalesOfficeID, DriverID, '4:Break' StopType, StopID /*Break at the store the driver will arrive next*/,
		 Null StopSequence, ProjectedArrivalTimeWithoutBreak PlannedArrivalTimeUTC, ProjectedBreakTimeInSec PlannedServiceTimeInSec, null
	From Operation.DeliveryPlan p
		Join 
		(
			Select DeliveryDate, RouteNumber, Max(RNKey) RNKey
			From Operation.DeliveryPlan
			Group By DeliveryDate, RouteNumber
			Having Count(Distinct DriverID) = 1
		) S on p.DeliveryDate = S.DeliveryDate And p.RouteNumber = S.RouteNumber And p.RNKey = S.RNKey
	Where ProjectedBreakTimeInSec > 0
	Order By DeliveryDate, SalesOfficeID, RouteNumber, PlannedArrivalTimeUTC

	---- Remove routes where more than one stops have the same arrival time - time estimate wouldn't make sense
	Declare @NonConclusive Table
	(
		DeliveryDate Date,
		RouteNumber varchar(20)
	)

	Insert Into @NonConclusive 
	Select DeliveryDate, RouteNumber
	From @D
	Group By DeliveryDate, RouteNumber, PlannedArrivalTimeUTC
	Having Count(*) > 1

	Delete D
	From @D d
	Join @NonConclusive s on d.DeliveryDate = s.DeliveryDate And d.RouteNumber = s.RouteNumber

	---------------------------
	Declare @Seq Table
	(
		DeliveryDate Date,
		RouteNumber varchar(20),
		PlannedArrivalTimeUTC DateTime2(0),
		StopSequence int
	)

	Insert @Seq
	Select DeliveryDate, RouteNumber, PlannedArrivalTimeUTC, Row_Number() Over(Partition By DeliveryDate, RouteNumber Order By PlannedArrivalTimeUTC) StopSequence
	From @D 

	--------------------------------------
	Delete 
	From Archive.Delivery
	Where DeliveryDate = @DeliveryDate

	Insert Into Archive.Delivery
	Select * From Operation.Delivery

	Truncate Table Operation.Delivery

	Insert Into Operation.Delivery(DeliveryDate,
		RouteNumber,
		SalesOfficeID,
		DriverID,
		StopType,
		StopID,
		StopSequence,
		PlannedArrivalTimeUTC,
		PlannedServiceTimeInSec,
		PlannedDrivingTimeInSec)
	Select d.DeliveryDate, d.RouteNumber, d.SalesOfficeID,
		d.DriverID,
		d.StopType,
		d.StopID,
		s.StopSequence,
		d.PlannedArrivalTimeUTC,
		d.PlannedServiceTimeInSec,
		PlannedDrivingTimeInSec
	From @D d
	Join @Seq s on d.DeliveryDate = s.DeliveryDate And d.RouteNumber = s.RouteNumber And d.PlannedArrivalTimeUTC = s.PlannedArrivalTimeUTC

Go

--exec ETL.pProcessPlannedDelivery

Print 'Creating ETL.pProcessPlannedDelivery'
Go

