use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('Operation.pGetDeliveryByRoute'))
Begin
	Drop Proc Operation.pGetDeliveryByRoute
	Print '* Operation.pGetDeliveryByRoute'
End
Go

/*
TESTING QUERY
exec Operation.pGetDeliveryByRoute @RouteNumber = 100961516, @DeliveryDate = '2017-03-24'

exec Operation.pGetDeliveryByRoute @RouteNumber = 110802201, @Debug = 1

exec Operation.pGetDeliveryByRoute @RouteNumber = 100901815, @DeliveryDate = '2017-03-20'

exec Operation.pGetDeliveryByRoute @RouteNumber = 100901815, @DeliveryDate = '2017-03-20', @Debug = 1

*/


Create Proc Operation.pGetDeliveryByRoute
(
	@RouteNumber varchar(20),
	@DeliveryDate Date = null,
	@Debug int = 0
)
As
	Set NOCOUNT ON;

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

	---------------------------
	Select Convert(varchar(10), d.DeliveryDate) DeliveryDate, 
		StopSequence - 1 StoreSequence, 
		StopType, AccountName + ', ' + Address + ', ' + City + ', ' + State Store
		, Convert(varchar(8), Case When OffSetToUTC is null Then PlannedArrivalTimeUTC Else DateAdd(hour, -1 * OffSetToUTC, PlannedArrivalTimeUTC) End, 114)
		 + ' ' + Case When OffSetToUTC is null Then 'GMT' Else rtz.TimeZone End FormattedPlannedDelivery
		--, Case When OffSetToUTC is null Then PlannedArrivalTimeUTC Else DateAdd(hour, -1 * OffSetToUTC, PlannedArrivalTimeUTC) End PlannedArrivalTime
		--, Case When OffSetToUTC is null Then 'GMT' Else rtz.TimeZone End TimeZone
		--, ActualArrivalTime, ActualArrivalTimeZone
		, Convert(varchar(8), ActualArrivalTime, 114) + ' ' + ActualArrivalTimeZone FormattedActualArrvial
		--, EstimatedArrivalTime, EstimatedArrivalTimeZone
		, Convert(varchar(8), EstimatedArrivalTime, 114) + ' ' + EstimatedArrivalTimeZone FormattedEstimatedArrvial
		--,up.FirstName, up.LastName, PlannedServiceTimeInSec
		, -1 * DateDiff(second, ActualArrivalTime, (Case When OffSetToUTC is null Then PlannedArrivalTimeUTC Else DateAdd(hour, -1 * OffSetToUTC, PlannedArrivalTimeUTC) End)) Plan_VS_Actual
		, -1 * DateDiff(second, ActualArrivalTime, EstimatedArrivalTime) Estimated_VS_Actual
	From Operation.Delivery d
	Left Join SAP.Account a on d.StopID = a.SAPAccountNumber
	Left Join Operation.RouteTimeZone rtz on d.DeliveryDate = rtz.DeliveryDate And d.RouteNumber = rtz.RouteNumber
	Left Join Setup.TimeConversion tc on rtz.TimeZone = tc.TimeZone
	Left Join Person.UserProfile up on d.LastUpdatedBy = up.GSN
	Where @DeliveryDate = d.DeliveryDate
	And @RouteNumber = d.RouteNumber
	And StopType like '2:%'
	Order By StopSequence

	---------------------------

 	If @Debug = 1
	Begin
		Select '--Execution Duration = ' + Convert(varchar, DateDiff(microsecond, @StartTime, Sysdatetime())) + ' micro seconds.'
	End
Go

--exec Operation.pGetDeliveryByRoute

Print 'Creating Operation.pGetDeliveryByRoute'
Go

