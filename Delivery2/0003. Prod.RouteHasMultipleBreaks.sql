Use Merch
Go

Select @@SERVERNAME Server
Go

Select DB_Name() As [Database]
Go

Select *
From SAP.Account
Where AccountName = 'H-E-B 000423'

Select *
From SAP.Account
Where SAPAccountNumber = 11300367


Select *
From Mesh.DeliveryStop
Where SAPAccountNumber = 11300367
And RouteID = 113802220

Select *
From Mesh.DeliveryStop
Where DeliveryDateUTC = '2018-10-11'
And RouteID = 113802220

Select *
From Mesh.Deliveryroute
Where DeliveryDateUTC = '2018-10-11'
And RouteID = 113802220

Select *
From Mesh.MyDayActivityLog
Where DeliveryDateUTC = '2018-10-11'
And RouteID = 113802220

use Merch
Go

-- Get request details --
Select Top 100 convert(Datetime2(1), l.RequestTime) ActivityTime, l.DeliveryDateUTC, l.GSN, l.RouteID,
	Case When e.LogID is null then 'Successful'
	Else 'Error'
	End Status,
	Substring(UserAgent, 0, 30) MyDayVersion,
	Convert(Datetime2(1), e.ServerInserttime) ExceptionTime, l.LogID ActivityLogID, e.LogID ExceptionLogID, l.WebEndPoint, l.StoredProc, l.GetParemeters, l.PostJson, e.GSN, e.Exception, e.ComputerName, e.UserAgent, e.ModifiedDate, l.CorrelationID
From Mesh.MyDayActivityLog l
Full outer join Setup.WebAPILog e on l.CorrelationID = e.CorrelationID
Where (l.CorrelationID is not null or e.CorrelationID is not null)
--And (l.GetParemeters like '%111501301%'  Or l.PostJson like '%111501301%'  )
--And e.LogID is Null
--And RouteID = 111501303
--And WEbEndPoint = 'UploadNewSequence'
--And e.LogID is not null
And DeliveryDateUTC = '2018-10-11'
And RouteID = 113802220
Order by coalesce(l.RequestTime, e.ServerInsertTime) Desc





Select DeliveryDateUTC, RouteID, Count(*)
From Mesh.PlannedStop
Where StopType <> 'STP'
And RouteID like '1104%'
Group by DeliveryDateUTC, RouteID
Having Count(*) > 2
Order By DeliveryDateUTC Desc, RouteID

Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-11'
And RouteID = 110402740
Order By Sequence

Select *
From SAP.Branch
Where SAPBranchID = '1104'

