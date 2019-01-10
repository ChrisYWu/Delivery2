Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select top 10 *
From Mesh.MyDayActivityLog
Where WebEndPoint = 'CheckInDeliveryStop'
And DeliveryDateUTC = '2019-01-09'
Order By LogID ASC
