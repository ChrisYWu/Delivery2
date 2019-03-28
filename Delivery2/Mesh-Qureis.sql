use Merch
Go

Select Top 1000 *
From ETL.DataLoadingLog

Select Top 1000 *
From Setup.WebAPILog
Where Exception like '%timeout%'
And OperationName = 'GetDeliveryManifest'
And ModifiedDate between '2019-03-25 06:00:00' And '2019-03-25 012:00:00' 
Order By ModifiedDate DEsc

Select Top 1000 *
From Mesh.MyDayActivityLog 
Where WebEndPoint = 'GetDeliveryManifest'
And RequestTime between '2019-03-25 04:00:00' And '2019-03-25 06:00:00' 
Order By LogID Desc


-- Get request details --
Select Top 100 convert(Datetime2(1), l.RequestTime) ActivityTime, l.DeliveryDateUTC, l.GSN, l.RouteID,
	Case When e.LogID is null then 'Successful'
	Else 'Error'
	End Status,
	Substring(UserAgent, 0, 30) MyDayVersion,
	Convert(Datetime2(1), e.ServerInserttime) ExceptionTime, l.LogID ActivityLogID, e.LogID ExceptionLogID, l.WebEndPoint, l.StoredProc, l.GetParemeters, l.PostJson, e.GSN, e.Exception, e.ComputerName, e.UserAgent, e.ModifiedDate, l.CorrelationID, e.CorrelationID
From Mesh.MyDayActivityLog l
Full outer join Setup.WebAPILog e on l.CorrelationID = e.CorrelationID
Where (l.CorrelationID is not null or e.CorrelationID is not null)
--And (l.GetParemeters like '%111501301%'  Or l.PostJson like '%111501301%'  )
--And e.LogID is Null
--And RouteID in (111502882, 111502864, 111502836)
--And WebEndPoint = 'UploadAddedStops'
--And WEbEndPoint = 'UploadNewSequence'
--And e.LogID is not null
and (DeliveryDateUTC = '2019-03-04')
--or DeliveryDateUTC = '2019-02-18')
--and RouteID Like '1116%'
Order by RouteID, coalesce(l.RequestTime, e.ServerInsertTime) Desc

Select Top 1 *
From Setup.WebAPILog
Order by LogID Desc


--Exec Mesh.pGetDeliveryManifest @RouteID = 112002021, @DeliveryDateUTC = '112002201'
--exec ETL.pLoadOrderPeriodically
--exec ETL.pLoadDeliverySchedulePeriodically

Select *
From mesh.DeliveryStop
Where RouteID = 102000910
And DeliveryDateUTC = '2019-02-26'
Order by Sequence

