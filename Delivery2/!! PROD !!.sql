Use Merch
Go

Select @@SERVERNAME
Go

Select DB_Name()
Go
----------------------------------
----------------------------------
----------------------------------


Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-15'
And RouteID = 117800011
Order By Sequence

Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-15'
And RouteID = 117800102
Order By Sequence
