Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = '2019-03-07' And RouteID = 112002011

Select b.BranchName, a.SAPAccountNumber, a.AccountName
From Mesh.PlannedStop ps
Join SAP.Account a on ps.SAPAccountNumber = a.SAPAccountNumber
Join SAP.Branch b on a.BranchID = b.BranchID
Where DeliveryDateUTC = '2019-03-07' And RouteID = 112002011
Order by Sequence

Select a.AccountName, ds.*
From Mesh.DeliveryStop ds
Join SAP.Account a on ds.SAPAccountNumber = a.SAPAccountNumber
Where DeliveryDateUTC = '2019-03-07' And RouteID = 112002011
Order by Sequence

-------------
/*
'ACHMX001' Mike
'VINPX001' Paul
*/


Select *
From APNS.AppUserToken
Where AppID = 2


Select *
From APNS.App

Select *
From APNS.Cert

Select *
From APNS.NotificationQueue

Select *
From APNSMerch.DeliveryInfo

Select *
From APNSMerch.StoreDeliveryTimeTrace




---- UpdateTime
--Update Mesh.PlannedStop
--Set PlannedArrival = DateAdd(Minute, 444, PlannedArrival)
--Where DeliveryDateUTC = '2019-03-07' And RouteID = 112002011

--Select DateDiff(minute, '2019-03-07 09:50:21', DateAdd(minute, 50, GetUTCDate()))


