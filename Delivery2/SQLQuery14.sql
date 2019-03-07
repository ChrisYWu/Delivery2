use Merch
Go

Select *
From Mesh.DeliveryRoute
Where RouteID = 111502701 
And DeliveryDateUTC = '2019-02-18'


Select *
From mesh.DeliveryStop
Where RouteID = 111502701 
And DeliveryDateUTC = '2019-02-18'
Order By Sequence