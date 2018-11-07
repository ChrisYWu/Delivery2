Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select inn.SAPAccountNumber, a.AccountName, a.City, a.State, a.PostalCode, b.SAPBranchID, b.BranchName, Convert(Date, ClientCheckINTime) CheckInDate
From Operation.MerchStopCheckIn inn
Join Operation.MerchStopCheckOut o on inn.MerchStopID = o.MerchStopID
Join SAP.Account a on inn.SAPAccountNumber = a.SAPAccountNumber
Join SAP.Branch b on a.BranchId = B.BranchID
Where SAPBranchID in 
(
	'1108',
	'1109',
	'1110',
	'1113',
	'1114',
	'1116',
	'1120'
)
And DispatchDate > '2017-10-01'
Order By Convert(Date, ClientCheckINTime) 


Select b.SAPBranchID, b.BranchName, a.SAPAccountNumber, a.AccountName, a.City,a.State, a.PostalCode, a.Latitude, a.Longitude
From SAP.Account a
Join SAP.Branch b on a.BranchId = B.BranchID
Where SAPBranchID in 
(
	'1108',
	'1109',
	'1110',
	'1113',
	'1114',
	'1116',
	'1120'
)
And a.Active = 1
Order BY SAPBranchID, SAPAccountNumber
