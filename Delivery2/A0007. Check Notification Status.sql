Use Merch
Go

Select @@SERVERNAME Server, DB_Name() As [Database]
Go

Select *
From Notify.StoreDeliveryMechandiser
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
Order By Delta
Go

Select GSN, dr.FirstName, dr.LastName, RouteID, DeliveryDateUTC DeliveryDate
From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryRoute dr
Join Portal_Data.Person.UserProfile up on dr.Lastname = up.LastName And dr.FirstName = up.FirstName
Where DeliveryDateUTC = Convert(Date, GetUTCDate())
And SAPBranchID in (1178)
And IsStarted = 0
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
and DeliveryDateUTC = Convert(Date, GetUTCDate())
and RouteID = 112001013
Order by coalesce(l.RequestTime, e.ServerInsertTime) Desc