Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select b.SAPBranchID, b.BranchName, m.MerchGroupID, mg.GroupName, m.GSN, m.TimeZoneOffSet, m.LastModified
From Setup.Merchandiser m
Join Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
Join SAP.Branch b on mg.SAPBranchID = b.SAPBranchID
Where GSN = 'WUXYX001'

exec ETL.pLoadDeliverySchedulePeriodically

Select *
From SEtup.Config


Select Top 100 *
From Setup.WebAPILog
Order By LogID desc


Update Setup.Merchandiser
Set TimeZoneOffSet = 0, MerchGroupID = 174
Where GSN = 'WUXYX001'

Select *
From Setup.MerchGroup
Where MerchGroupID = 39

Select b.*, m.*
From SEtup.MerchGroup m
Join SAP.Branch b on m.SAPBranchID = b.SAPBranchID
Where b.SAPBranchID = '1103'

Select *
From Setup.Config

Select RouteID, Count(*)
From Mesh.PlannedStop
Where DeliveryDateUTC = Convert(Date, GetDate())
And SAPAccountNumber in (
Select SAPAccountNumber
From Setup.Store
Where MerchGroupID = 174
)
Group By RouteID

Select *
From APNSMerch.DeliveryInfo
Where DeliveryDateUTC = Convert(Date, GetDate())
And MerchandiserGSN = 'WUXYX001'

Select *
From mesh.DeliveryStop
Where DeliveryDateUTC = Convert(Date, GetDate())
And RouteID = 110302824


Select *
From APNS.NotificationQueue

exec  APNS.pGetMessagesForNotification @LockerID='00', @Debug=1


Select *
From SEtup.Merchandiser
Where GSN = 'WUXYX001'


Select *
From mesh.PlannedStop
Where DeliveryDateUTC = '2019-01-24'
And RouteID like '1103%'

Select *
From mesh.DeliveryStop
Where DeliveryDateUTC = '2019-01-24'

Select *
From APNS.AppUsertoken


