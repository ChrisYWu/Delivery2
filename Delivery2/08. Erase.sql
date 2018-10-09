use DSDDelivery
Go

Select [StopSequence], [PlannedServiceTimeInSec], [PlannedDrivingTimeInSec], [ActualArrivalTime], [ActualDepartureTime], [EstimatedArrivalTime]
, DateAdd(second,  [PlannedServiceTimeInSec], ActualArrivalTime) ProjectedDeparture
From Operation.Delivery
Where RouteNumber = 110802201

--Update Operation.Delivery
--Set ActualArrivalTime = null, 
--[ActualArrivalTimeZone] = null,
--[ActualDepartureTime] = null,
--[ActualDepartureTimeZone] = null,
--[EstimatedArrivalTime] = null,
--[EstimatedArrivalTimeZone] = null,
--[LastUpdatedTimeUTC] = null,
--[LastUpdatedBy] = null,
--[LastUpdatedDriverID] = null
