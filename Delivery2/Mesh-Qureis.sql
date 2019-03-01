use Merch
Go

Select Count(*)
From Mesh.CustomerInvoice

Select Count(*)
From Mesh.InvoiceItem


SElect *
From Mesh.DeliveryStop
Where RouteID in (102000910
,102000911
,102000913
,102000915
)
--And ISaddedByDriver = 0
Order By RouteID, Sequence


Select Convert(datetime2(0), RequestTime), Count(*)
From Mesh.MyDayActivityLog
Where DeliveryDateUTC > '2019-02-26'
Group By Convert(datetime2(0), RequestTime)
Order By Convert(datetime2(0), RequestTime) Desc

Select WebEndPoint, Count(*) Cnt
From Mesh.MyDayActivityLog
Where DeliveryDateUTC > '2019-02-27'
Group By WebEndPoint
Order By Count(*) ASC

Select Top 100 *
From Mesh.MyDayActivityLog
Where DeliveryDateUTC = '2019-03-01'
And PostJson like '%3516307362%'
----Where CorrelationID = 'c5690851-be48-40ae-be24-ec019b32'
Order By LogID Desc

Select *
From Setup.WebAPILog
Where CorrelationID in ('ebb246e4-c6dc-4174-827e-8a8d9b70',
'fb235f2e-96fe-42d6-b2fb-e2c8e42f',
'cfb7cc58-a09c-4419-9d2b-e5e48712',
'e07dafec-dd35-4edd-952d-e907cafb')

Select DeliveryDateUTC, RouteID, LastModifiedBy
From Mesh.DeliveryRoute
Where RouteID in (111502882, 111502864, 111502836)
Order by DeliveryDateUTC desc

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
and (DeliveryDateUTC = '2019-03-01')
--or DeliveryDateUTC = '2019-02-18')
--and RouteID Like '1116%'
And Json like '%3516307362%'
Order by RouteID, coalesce(l.RequestTime, e.ServerInsertTime) Desc

--Exec Mesh.pGetDeliveryManifest @RouteID = 112002021, @DeliveryDateUTC = '112002201'
--exec ETL.pLoadOrderPeriodically
--exec ETL.pLoadDeliverySchedulePeriodically

Select *
From mesh.DeliveryStop
Where RouteID = 102000910
And DeliveryDateUTC = '2019-02-26'
Order by Sequence

