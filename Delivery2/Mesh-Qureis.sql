use Merch
Go

Select Convert(datetime2(0), RequestTime), Count(*)
From Mesh.MyDayActivityLog
Where DeliveryDateUTC > '2019-02-24'
Group By Convert(datetime2(0), RequestTime)
Order By Convert(datetime2(0), RequestTime) Desc

Select Top 100 *
From Mesh.MyDayActivityLog
Order By LogID Desc

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
And RouteID in (118400029)
--And WEbEndPoint = 'UploadNewSequence'
--And e.LogID is not null
--and (DeliveryDateUTC = '2019-02-19'
--or DeliveryDateUTC = '2019-02-18')
--and RouteID Like '1116%'
Order by coalesce(l.RequestTime, e.ServerInsertTime) Desc

--Exec Mesh.pGetDeliveryManifest @RouteID = 112002021, @DeliveryDateUTC = '112002201'
--exec ETL.pLoadOrderPeriodically
--exec ETL.pLoadDeliverySchedulePeriodically

