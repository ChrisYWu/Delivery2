use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('Operation.pGetDriverDeliveryPlan'))
Begin
	Drop Proc Operation.pGetDriverDeliveryPlan
	Print '* Operation.pGetDriverDeliveryPlan'
End
Go

/*
TESTING QUERY
exec Operation.pGetDriverDeliveryPlan @RouteNumber = 109200847, @DeliveryDate = '2017-02-27', @TimeZone = 'CST'

exec Operation.pGetDriverDeliveryPlan @RouteNumber = 109200847, @DeliveryDate = '2017-02-27', @TimeZone = 'CST'

exec Operation.pGetDriverDeliveryPlan @RouteNumber = 109200847, @DeliveryDate = '2017-02-27', @TimeZone = 'CST', @Debug = 1

exec Operation.pGetDriverDeliveryPlan @RouteNumber = 102000768, @DeliveryDate = '2017-02-28', @TimeZone = 'CST', @Debug = 1

exec Operation.pGetDriverDeliveryPlan @RouteNumber = 107600354, @TimeZone = 'CDT'

Select (3474 + 377) / 60

*/

Create Proc Operation.pGetDriverDeliveryPlan
(
	@RouteNumber varchar(20),
	@DeliveryDate Date = null,
	@TimeZone varchar(5),
	@IncludeBreakRoutes bit = 0,
	@Debug int = 0
)
As
	If @Debug = 1
	Begin
		Declare @StartTime DateTime2(7) = Sysdatetime()
	End

	If (@DeliveryDate is null)
		Set @DeliveryDate = Convert(Date, GetDate())

	If @Debug = 1
	Begin
		Select @DeliveryDate DeliveryDate
	End

	Set NOCOUNT ON;
	Declare @RNKeyCount int
	Declare @DriverCount int
	Declare @AccumulatedProjectedBreakTime int

	Select @TimeZone = LTrim(RTrim(@TimeZone))
	If (IsNull(@TimeZone, '') = '')
	Begin
		Select @TimeZone = 'GMT'
	End

	
	Select @RNKeyCount = Count(Distinct RNKey), @DriverCount = Count(Distinct DriverID), @AccumulatedProjectedBreakTime = Sum(IsNull(ProjectedBreakTimeInSec, 0))
	From Operation.DeliveryPlan
	Where @DeliveryDate = DeliveryDate
	And @RouteNumber = RouteNumber

	Declare @ErrorMsg varchar(500) = 'Delivery Date = ' + Convert(varchar, @DeliveryDate) 
		+ '; RouteNumber = ' + Convert(varchar, @RouteNumber)
		+ '; TimeZone = ' + Convert(varchar, @TimeZone)

	If Not Exists(Select * From Setup.TimeConversion Where TimeZone = @TimeZone)
	Begin
		Set @ErrorMsg = 'Not specific TimeZone is found in configuration. ' + @ErrorMsg
		RAISERROR ( @ErrorMsg, -- Message text.  
					16, -- Severity.  
					1 -- State.  
		);
	End
	Else
	Begin
		If Exists (Select * From Operation.RouteTimeZone Where RouteNumber = @RouteNumber And DeliveryDate = @DeliveryDate)
		Begin
			Update Operation.RouteTimeZone Set TimeZone = @TimeZone Where RouteNumber = @RouteNumber And DeliveryDate = @DeliveryDate
		End
		Else
		Begin
			Insert Into Operation.RouteTimeZone Values(@DeliveryDate, @RouteNumber, @TimeZone)			
		End
	End

	--------------------------------------------------------
	-- We're taking the latest session.
	--If @RNKeyCount > 1 
	--Begin
	--	Set @ErrorMsg = 'More than one schedule session(RNSession) found. ' + @ErrorMsg
	--	RAISERROR ( @ErrorMsg, -- Message text.  
	--				16, -- Severity.  
	--				1 -- State.  
	--	);
	--End
	
	If @DriverCount > 1
	Begin
		Set @ErrorMsg = 'More than one drivers are found in this route for the day. ' + @ErrorMsg
		RAISERROR ( @ErrorMsg, -- Message text.  
					16, -- Severity.  
					1 -- State.  
		);
	End

	If (@IncludeBreakRoutes = 0 And @AccumulatedProjectedBreakTime > 0) 
	Begin
		Set @ErrorMsg = 'The planned schedule has one or more break(s) in it. ' + @ErrorMsg
		RAISERROR ( @ErrorMsg, -- Message text.  
					16, -- Severity.  
					1 -- State.  
		);
	End

	If @@ERROR = 0
	Begin
		Select Convert(varchar(10), d.DeliveryDate) DeliveryDate, d.RouteNumber, DriverID, StopSequence, StopType, StopID, DateAdd(hour, -1 * OffSetToUTC, PlannedArrivalTimeUTC) PlannedArrivalTime, ActualArrivalTime, tc.TimeZone, 
		PlannedServiceTimeInSec, PlannedDrivingTimeInSec PlannedTravelTimeFromPreviousStop
		From Operation.Delivery d
		Join Operation.RouteTimeZone rtz on d.DeliveryDate = rtz.DeliveryDate And d.RouteNumber = rtz.RouteNumber
		Join Setup.TimeConversion tc on rtz.TimeZone = tc.TimeZone
		Where @DeliveryDate = d.DeliveryDate
		And @RouteNumber = d.RouteNumber
		Order By StopSequence

 		If @Debug = 1
		Begin
			Select '--Execution Duration = ' + Convert(varchar, DateDiff(microsecond, @StartTime, Sysdatetime())) + ' micro seconds.'
		End
	End
Go

--exec Operation.pGetDriverDeliveryPlan

Print 'Creating Operation.pGetDriverDeliveryPlan'
Go

