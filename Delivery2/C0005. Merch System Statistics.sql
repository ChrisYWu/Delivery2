Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

/*
1. Collecting 35K images every day, total of 11 milion images
*/
Select IsOrphaned, Count(*) Cnt
From Operation.AzureBlobStorage
Group By IsOrphaned

Select Y, M, D, IsOrphaned, Count(*) Cnt
From (
	Select *, DatePart(Year, LastModified) Y, DatePart(Month, LastModified) M, Datepart(Day, LastModified) D
	From Operation.AzureBlobStorage
	--Where IsOrphaned = 1
) temp
Group by Y, M, D, IsOrphaned
Order by Y, M, D

/*
2. 50K daily writes(uploads) from merchandisers daily
12 hours of active time on average
Traffic starts at 5 am(over 1000 uploads) till 4pm(1000)

*/
Select OperationDate, Count(*) Cnt
From Operation.GSNActivityLog
Group By OperationDate
Order by OperationDate Desc

Select OperationDate, Min(UTCInsertTime) MinTime, Max(UTCInsertTime) Maxtime
From Operation.GSNActivityLog
Where OperationDate > DateAdd(Day, -14, GetDate()) And OperationDate <= Convert(Date, GetDate())
Group By OperationDate

Select OperationDate, Datepart(Hour, UTCInsertTime) - 6 as Hr, Count(*) Cnt 
From Operation.GSNActivityLog
Where OperationDate > DateAdd(Day, -3, GetDate()) And OperationDate <= Convert(Date, GetDate())
Group By OperationDate, Datepart(Hour, UTCInsertTime) 

/*
3. Registered user over life time: 7.8K
Active merchandisers: 3.6K
800~1000 dispatches every day
4000 Route Updates every day

*/
Select Count(*)
From Setup.Person

Select DispatchDate, Count(*) Cnt
From Planning.DispatchBatch
Where DispatchDate > DateAdd(Day, -14, GetDate())
Group By DispatchDate
Order By DispatchDate

Select Distinct GSN
From Planning.Dispatch
Where DispatchDate > DateAdd(Day, -2, GetDate())

Select DispatchDate, Count(*) Cnt
From (
	Select DispatchDate, LastModified
	From Planning.PreDispatch
	Where DispatchDate > DateAdd(Day, -14, GetDate()) And DispatchDate <= Convert(Date, GetDate())
	Group By DispatchDate, LastModified
) tmp
Group By DispatchDate
Order By DispatchDate


/*
Fidn today's built
*/

Select GroupName, inn.SAPAccountNumber, AccountName, a.State
From Operation.MerchStopCheckIn inn 
Join SEtup.MerchGroup m on inn.MerchGroupID = m.MerchGroupID
Join SAP.Account a  on a.SAPAccountNumber = inn.SAPAccountNumber
	Where inn.SAPAccountNumber in (
	Select Top 100 SAPAccountNumber
	From Operation.DisplayBuild db
	Join Operation.DisplayBuildExecution dbe on db.LatestExecutionID = dbe.DisplayBuildExecutionID
	Where dbe.BuildStatusID = 2
	Order By dbe.LastModified desc
	)
And Inn.DispatchDate = Convert(DAte, GEtDAte())
Order By GroupName

