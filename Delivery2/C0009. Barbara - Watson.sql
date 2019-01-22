Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From Setup.Person
Where LastName = 'Watson'

Select *
From Setup.UserLocation
Where GSN = 'WATZX001'

Select *
From Setup.MerchGroup
Where SAPBranchID = 1062

Select *
From Planning.Route
Where RouteName = 'fargo 3'


Select p.*, a.AccountName
From Planning.PreDispatch p
Join SAP.Account a on p.SAPAccountNumber = a.SAPAccountNumber
Where DispatchDate = DateAdd(day, -1, Convert(Date, SysDateTime()))
And RouteID = 3206
Order By Sequence

Select p.*, a.AccountName
From Planning.Dispatch p
Join SAP.Account a on p.SAPAccountNumber = a.SAPAccountNumber
Where DispatchDate = DateAdd(day, -1, Convert(Date, SysDateTime()))
And RouteID = 3206
And InvalidatedBatchID is null
Order By Sequence


Select *
From Planning.RouteStoreWeekday
Where RouteID = 3206
And DayOfWeek = 5
Order By Sequence

Select *
From Planning.PreDispatch p
Where Sequence = 0
Order By DispatchDate

Select *
From Planning.RouteStoreWeekday p
Where Sequence < 0

--And DispatchDate >= Convert(Date, GetDate())


