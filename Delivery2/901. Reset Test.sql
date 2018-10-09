use DSDDelivery
Go


Select *
From Operation.Delivery
Where RouteNumber = 110802201

Update Operation.Delivery
Set EstimatedArrivalTime = DateAdd(Second, -18000+500, PlannedArrivalTimeUTC), EstimatedArrivalTimeZone = 'CDT'
, ActualArrivalTime = DateAdd(Second, -18000+500, PlannedArrivalTimeUTC), ActualArrivalTimeZone = 'CDT'
Where RouteNumber = 100961516
And StopID = 11506288

