Use Merch
Go

Select @@SERVERNAME
Go

Select DB_Name()
Go

Select *
From SAP.Branch
Where BranchName = 'Denver'

Select Distinct RouteID
From Mesh.PlannedStop
Where DeliveryDateUTC > '2018-10-15'
And RouteID Like '1103%'
And StopType Not In ('STP', 'B')
Order By Sequence

----------------------------------
----------------------------------
----------------------------------


Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-15'
And RouteID = 117800011 
Order By Sequence

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
And DeliveryDateUTC = '2018-10-15'
And RouteID = 117800011 
Order by coalesce(l.RequestTime, e.ServerInsertTime) Desc

Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-15'
And RouteID = 117800102
Order By Sequence

Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-16'
And RouteID like '1178%'
And StopType = 'PW'
Order By Sequence

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = '2018-10-16'
And RouteID in (117800102, 117800021)

Update
Mesh.DeliveryRoute
Set LastManifestFetched = null
Where DeliveryDateUTC = '2018-10-16'
And RouteID in (117800102, 117800021)


