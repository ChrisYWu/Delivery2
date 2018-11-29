Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Update Mesh.DeliveryRoute
Set ActualStartTime = null
Where RouteID = 999117800010
And DeliveryDateUTC = Convert(Date, GetDate())

Select *
From Mesh.DeliveryRoute
Where RouteID = 999117800010
And DeliveryDateUTC = Convert(Date, GetDate())

Delete Mesh.DeliveryStop
Where RouteID = 999117800010
And DeliveryDateUTC = Convert(Date, GetDate())


Select *
From Mesh.DeliveryStop
Where RouteID = 999117800010
And DeliveryDateUTC = Convert(Date, GetDate())
Order By Sequence

Select *
From Mesh.PlannedStop
Where RouteID = 999117800010
And DeliveryDateUTC = Convert(Date, GetDate())
Order By Sequence
