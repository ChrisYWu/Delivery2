/*
1. exec ETL.pLoadDeliveryPlanFromRN;
2. exec ETL.pMergeDeliveryPlan;
3. exec ETL.pProcessPlannedDelivery;


*/

use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('Testing.pResetRouteDeliveryTime'))
Begin
	Drop Proc Testing.pResetRouteDeliveryTime
	Print '* Testing.pResetRouteDeliveryTime'
End
Go

/*
TESTING QUERY

exec Testing.pResetRouteDeliveryTime @RouteNumber=100961516, @DeliveryDate='2017-03-24'

*/

Create Proc Testing.pResetRouteDeliveryTime
(
	@RouteNumber varchar(20),
	@DeliveryDate Date = null
)
As
	Set NOCOUNT ON;  

	Update Operation.Delivery
	Set ActualArrivalTime = null, 
		[ActualArrivalTimeZone] = null,
		[ActualDepartureTime] = null,
		[ActualDepartureTimeZone] = null,
		[EstimatedArrivalTime] = null,
		[EstimatedArrivalTimeZone] = null,
		[LastUpdatedTimeUTC] = null,
		[LastUpdatedBy] = null,
		[LastUpdatedDriverID] = null
	Where RouteNumber = @RouteNumber
	And DeliveryDate = @DeliveryDate
Go

--exec Testing.pResetRouteDeliveryTime

Print 'Creating Testing.pResetRouteDeliveryTime'
Go

