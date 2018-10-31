use Merch
Go

/*
Update Mesh.DeliveryRoute
Set LastManifestFetched = Null
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID Like 113302005
*/

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID Like 113302005

Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID = 113302005
Order by Sequence

exec Mesh.pGetDeliveryManifest @RouteID = 113302005

Select *
From Mesh.DeliveryStop
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID = 113302005
Order by Sequence


