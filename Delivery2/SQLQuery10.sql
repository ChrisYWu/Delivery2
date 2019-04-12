use Merch
Go

Select *
From APNS.NotificationQueue

Select *
From APNSMerch.DeliveryInfo

Select Top 1000 *
From Setup.WebAPILog
Order By LogID Desc


Select *
From Mesh.DeliveryStop
Where SAPAccountNumber = 11293013
order by DeliveryDateUTC desc

Declare @Known APNSMerch.tDeliveries 
Insert @Known
Values(49093, Null)

exec APNSMerch.pUpdateDeliveries @Known	

Select *
From APNSMerch.StoreDeliveryTimeTrace
Where SAPAccountNumber = 11293013
order by ReportTimeLocal desc

Select 
	sm.DeliveryDateUTC,
	sm.SAPAccountNumber,
	p.GSN,
	--'[' + b.BranchName + ']' + 
	Case 
		When sm.DNS = 1 Then 'Delivery for ' 
		When sm.IsEstimated = 1 Then 'The new estimated delivery arrival for ' 
		Else 'Delivery for ' End 
	+
	--Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
	Concat(A.AccountName, ', ', A.Address, ', ', a.City, ' ')
	+
	Case When sm.DNS = 1 Then 'is canceled'  
		When sm.IsEstimated = 1 Then 'is ' 
		Else 'is arrived at ' End 
	+
	Case When sm.DNS = 1 Then '' 
		Else Ltrim(Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, sm.ArrivalTime), 100), 13, 100)) End Message
	From @DeliveryInfo ds
	Join APNSMerch.DeliveryInfo sm on sm.SAPAccountNumber = ds.SAPAccountNumber And ds.DeliveryDateUTC = sm.DeliveryDateUTC
	Join Setup.Merchandiser p on sm.MerchandiserGSN = p.GSN
	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	Join SAP.Branch b on a.BranchID = b.BranchID
	And (( Delta > 1800 ) Or ( Delta <> 0 And sm.IsEstimated = 0))

