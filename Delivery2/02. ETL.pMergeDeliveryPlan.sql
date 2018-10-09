use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('ETL.pMergeDeliveryPlan'))
Begin
	Drop Proc ETL.pMergeDeliveryPlan
	Print '* ETL.pMergeDeliveryPlan'
End
Go

/*
--exec ETL.pMergeDeliveryPlan

*/

Create Proc ETL.pMergeDeliveryPlan
As
	Set NoCount On;
	
	/*	
		Key Note:
		[DeliveryDate] ASC,
		[RouteNumber] ASC This might not need to be part of the key,
		[StopType] ASC,
		[StopID] ASC,
		[PlannedArrivalTime] This is part of the key because a store can show up more than once,
		[DriverID] This is part of the key because a route can be split between drivers

	-----------------------------------------
		Best if run only once a day
	*/

	Declare @DeliveryDate Date
	Select Top 1 @DeliveryDate = DELIVERYDATE
	From Staging.RNDeliveryPlan

	Declare @DateRange Table
	(
		DeliveryDate Date
	)

	If Not Exists (Select * From Archive.DeliveryPlan Where DeliveryDate = @DeliveryDate)
	Begin
		---- Archiving logic
		Insert @DateRange
		Select Distinct DeliveryDate From Operation.DeliveryPlan

		Delete From Archive.DeliveryPlan
		Where DeliveryDate in (Select DeliveryDate From @DateRange)

		Insert Archive.DeliveryPlan
		Select * From Operation.DeliveryPlan

		Truncate Table Operation.DeliveryPlan
		
		---- Clean up the time zone infomation also ---
		Truncate Table Operation.RouteTimeZone
	End

	If Not Exists (Select * From Archive.Delivery Where DeliveryDate = @DeliveryDate)
	Begin
		---- Archiving logic
		Delete From @DateRange 

		Insert @DateRange
		Select Distinct DeliveryDate From Operation.Delivery

		Delete From Archive.Delivery
		Where DeliveryDate in (Select DeliveryDate From @DateRange)

		Insert Archive.Delivery
		Select * From Operation.Delivery

		Truncate Table Operation.Delivery
	End

	Merge Into Operation.DeliveryPlan t
	Using 
	(
		Select [DELIVERYDATE], [RNKey], [ROUTE_NUMBER], [STOP_TYPE], [STOP_ID], [ARRIVALTIME], 
			Max([TRAVEL_TIME_INSECONDS]) TRAVEL_TIME_INSECONDS, 
			Max([SERVICE_TIME_INSECONDS]) SERVICE_TIME_INSECONDS, 
			Max([SALESOFFICE_ID]) SALESOFFICE_ID,
			Max([DRIVERID]) DRIVERID,
			Max([DRIVER_FNAME]) DRIVER_FNAME,
			Max([DRIVER_LNAME]) DRIVER_LNAME,
			Max([DRIVER_PHONE_NUM]) DRIVER_PHONE_NUM
		From Staging.RNDeliveryPlan 
		Group By [DELIVERYDATE], [RNKey], [ROUTE_NUMBER], [STOP_TYPE], [STOP_ID], [ARRIVALTIME]
	)
	inn
	On t.DeliveryDate = inn.DELIVERYDATE and Substring(t.StopType, 3, 99) = inn.STOP_TYPE and t.StopID = inn.STOP_ID and t.RouteNumber = inn.ROUTE_NUMBER and t.PlannedArrivalTime = inn.ARRIVALTIME and t.DriverID = inn.DRIVERID And t.RNKey = inn.RNKey
	When Matched
	Then Update Set
		t.PlannedTravelTimeInSec = inn.TRAVEL_TIME_INSECONDS,
		t.PlannedServiceTimeInSec = inn.SERVICE_TIME_INSECONDS,
		t.SalesOfficeID = inn.SALESOFFICE_ID,
		t.DriverFirstName = inn.DRIVER_FNAME,
		t.DriverLastName = inn.DRIVER_LNAME,
		t.DriverPhoneNumber = inn.DRIVER_PHONE_NUM,
		t.UpdatedBy = 'RoadNetJob', 
		t.ClientTime = SysDateTime(), 
		t.ClientTimeZone = DATENAME(TZOFFSET , SYSDATETIMEOFFSET()),
		t.UpdateTimeUTC = SysUTCDateTime()
	When Not Matched By Target Then
		Insert(DeliveryDate, RnKey, SalesOfficeID, RouteNumber, StopType, StopID, PlannedTravelTimeInSec, PlannedArrivalTime, PlannedServiceTimeInSec, DriverID, DriverFirstName, DriverLastName, DriverPhoneNumber, DeletedFromRN, UpdatedBy, ClientTime, ClientTimeZone, UpdateTimeUTC)
		Values(inn.DELIVERYDATE, RnKey, SALESOFFICE_ID, ROUTE_NUMBER, Case When STOP_TYPE = 'Store' Then '2:Store' When STOP_TYPE = 'BRANCHSTART' Then '1:BranchStart' When STOP_TYPE = 'BRANCHReturn' Then '3:BranchReturn' End, STOP_ID, TRAVEL_TIME_INSECONDS, ARRIVALTIME, SERVICE_TIME_INSECONDS, DRIVERID, DRIVER_FNAME, DRIVER_LNAME, DRIVER_PHONE_NUM, 0, 'RoadNetJob', SysDateTime(), DATENAME(TZOFFSET , SYSDATETIMEOFFSET()), SysUTCDateTime())
	When Not Matched By Source Then
		Update Set
		t.DeletedFromRN = 1;
Go

Print 'Creating ETL.pMergeDeliveryPlan'
Go

