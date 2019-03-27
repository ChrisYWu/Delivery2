use Merch
Go

Select *
From Setup.Person
Where LastName = 'Hendrickson'

Select *
From SEtup.Merchandiser
Where GSN = 'HENCL001'

Select *
From Portal_Data.Staging.ADExtractData
Where UserID = 'HENCL001'

exec Planning.pGetMerchProfileByGSN @GSN = 'HENCL001'

Select *
From SAP.Branch
Where ZipCode like '57104%'

Select b.*, c.*
From Operation.MerchStopCheckIn c
Join SAP.Account a on c.SAPAccountNumber = a.SAPAccountNumber
Join SAP.Branch b on a.BranchID = b.BranchID
Where GSN = 'HENCL001'
Order By DispatchDate DEsc

Select *
From setup.MerchGroup
Where MerchGroupID = 309

Select *
From SAP.Branch
Where SAPBranchID = '1060'

Select Min(DispatchDAte)
From Planning.Dispatch
Order by DispatchDate

Where GSN = 'HENCL001'





