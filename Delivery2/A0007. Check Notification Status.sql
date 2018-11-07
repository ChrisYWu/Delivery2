Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From [ETL].[DataLoadingLog]

Select *
From [Mesh].[PlannedStop]
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID like '1178%'


Select *
From SAP.Branch
Where Branchname = 'Denver'

--Select *
--From Notify.StoreDeliveryMechandiser
--Where DeliveryDateUTC = Convert(Date, GetUTCDate())
--Order By Delta
--Go


-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
-- Who didn't start the route?
Select GSN, dr.FirstName, dr.Lastname, RouteID, dr.LastManifestFetched --b.SAPBranchID, BranchName, DeliveryDateUTC, RouteID, dr.FirstName, dr.Lastname, DeliveryDateUTC DeliveryDate, dr.LastManifestFetched, IsStarted, ActualStartGSN
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryRoute dr
Left Join Portal_Data.Person.UserProfile up on dr.Lastname = up.LastName And dr.FirstName = up.FirstName
Join SAP.Branch b on dr.SAPBranchID = b.SAPBranchID
Where DeliveryDateUTC = dateadd(day, 0, convert(Date, GetUTCDate()))
And b.SAPBranchID in ('1178')
--And IsStarted = 0
Order By dr.RouteID, dr.DeliveryDateUTC
Go

-- For the ones started, how are their stops look like?
Select *
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop
Where DeliveryDateUTC = Convert(Date, GetDate())
And RouteID 
In
(
	Select RouteID
	From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryRoute dr
	Join SAP.Branch b on dr.SAPBranchID = b.SAPBranchID
	Where DeliveryDateUTC = convert(Date, GetUTCDate())
	And b.SAPBranchID in ('1178')
	And IsStarted = 1
)
Order By RouteID, Sequence
Go

-----------------------------------------------------------------------------------
-----------------------------------------------------------------------------------
Select *
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop dr
Where DeliveryDateUTC = DateAdd(day, -1, Convert(Date, GetUTCDate()))
And RouteID = 117800102
Order By Sequence

Select RouteID, Sequence, StopType, SAPAccountNumber, TravelToTime, ServiceTime
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop dr
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID = 117800010
Order By Sequence

Select RouteID, Sequence+1 Sequence, StopType, SAPAccountNumber, TravelToTime, ServiceTime
From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop dr
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And RouteID = 117800010
Order By Sequence

Select RouteID, Sequence+1 Sequence, StopType, SAPAccountNumber, TravelToTime, ServiceTime
From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop dr
Where DeliveryDateUTC = DateAdd( day, -1, convert(Date, GetUTCDate()))
--Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And (RouteID like '1120%' or RouteID like '1138%')
And StopType Not in ('STP', 'B')
Order By RouteID


-- Who didn't start the route?
Select Distinct SAPAccountNumber
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryRoute dr
Join DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds on dr.RouteID = ds.RouteID And ds.DeliveryDAteUTC = dr.DeliveryDateUTC
Where dr.DeliveryDateUTC = Convert(Date, GetUTCDate())
And SAPBranchID in (1178)
And IsStarted = 1
And SAPAccountNumber is not null
Go

--
exec Notify.p0DriverUpdate
Go

Select *
From Notify.StoreDeliveryMechandiser
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
Order By SAPBranchID, SAPAccountNumber

--Where SAPAccountNumber in 
--(
--	Select SAPAccountNumber
--	From DPSGSHAREDCLSTR.Merch.Planning.Dispatch d
--	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup m on d.MerchGroupID = m.MerchGroupID
--	Where SAPBranchID = 1178
--	And DispatchDate = Convert(Date, GetDate())
--	And InvalidatedBatchID is null
--	And SAPAccountNumber in 
--	(
--		Select Distinct SAPAccountNumber
--		From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryRoute dr
--		Join DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds on dr.RouteID = ds.RouteID And ds.DeliveryDAteUTC = dr.DeliveryDateUTC
--		Where dr.DeliveryDateUTC = Convert(Date, GetUTCDate())
--		And SAPBranchID in (1178)
--		And IsStarted = 1
--		And SAPAccountNumber is not null
--	)
--)

--Update sdm
--Set SAPBranchID = b.SAPBranchID
--From Notify.StoreDeliveryMechandiser sdm
--Join SAP.Account a on sdm.SAPAccountNumber = a.SAPAccountNumber
--Join SAP.Branch b on a.BranchID = b.BranchID

-- Get request details --
Select Top 100 convert(Datetime2(1), l.RequestTime) ActivityTime, l.DeliveryDateUTC, l.GSN, l.RouteID,
	Case When e.LogID is null then 'Successful'
	Else 'Error'
	End Status,
	Substring(UserAgent, 0, 30) MyDayVersion,
	Convert(Datetime2(1), e.ServerInserttime) ExceptionTime, l.LogID ActivityLogID, e.LogID ExceptionLogID, l.WebEndPoint, l.StoredProc, l.GetParemeters, l.PostJson, e.GSN, e.Exception, e.ComputerName, e.UserAgent, e.ModifiedDate, l.CorrelationID
From DPSGSHAREDCLSTR.Merch.Mesh.MyDayActivityLog l
Full outer join DPSGSHAREDCLSTR.Merch.Setup.WebAPILog e on l.CorrelationID = e.CorrelationID
Where (l.CorrelationID is not null or e.CorrelationID is not null)
--And (l.GetParemeters like '%111501301%'  Or l.PostJson like '%111501301%'  )
--And e.LogID is Null
--And RouteID = 111501303
--And WEbEndPoint = 'UploadNewSequence'
--And e.LogID is not null
And DeliveryDateUTC = DateAdd( day, -0, convert(Date, GetUTCDate()))
--and DeliveryDateUTC = Convert(Date, GetUTCDate())
and RouteID in (
--117800010,
--117800011,
117800021,
117800022,
117800023
--117800102
)
Order by RouteID, coalesce(l.RequestTime, e.ServerInsertTime) Desc

Go

-- Get request details --
Select Top 100 convert(Datetime2(1), l.RequestTime) ActivityTime, l.DeliveryDateUTC, l.GSN, l.RouteID,
	Case When e.LogID is null then 'Successful'
	Else 'Error'
	End Status,
	Substring(UserAgent, 0, 30) MyDayVersion,
	Convert(Datetime2(1), e.ServerInserttime) ExceptionTime, l.LogID ActivityLogID, e.LogID ExceptionLogID, l.WebEndPoint, l.StoredProc, l.GetParemeters, l.PostJson, e.GSN, e.Exception, e.ComputerName, e.UserAgent, e.ModifiedDate, l.CorrelationID
From DPSGSHAREDCLSTR.Merch.Mesh.MyDayActivityLog l
Full outer join DPSGSHAREDCLSTR.Merch.Setup.WebAPILog e on l.CorrelationID = e.CorrelationID
Where (l.CorrelationID is not null or e.CorrelationID is not null)
--And (l.GetParemeters like '%111501301%'  Or l.PostJson like '%111501301%'  )
--And e.LogID is Null
--And RouteID = 111501303
--And WEbEndPoint = 'UploadNewSequence'
--And e.LogID is not null
And DeliveryDateUTC = DateAdd( day, -1, convert(Date, GetUTCDate()))
--and DeliveryDateUTC = Convert(Date, GetUTCDate())
and RouteID = 117800102
Order by RouteID, coalesce(l.RequestTime, e.ServerInsertTime) Desc