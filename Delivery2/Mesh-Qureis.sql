use Merch
Go

Select *
From ETL.DataLoadingLog

Select Top 1 *
From Mesh.CustomerOrder
Where SAPAccountNumber = 12270286
And DeliveryDateUTC = Convert(Date, GetDate())

Select *
From mesh.DeliveryRoute
Where routeID = 113102021
Order By DeliveryDateUTC Desc

Select *
From Mesh.DeliveryStop
Where SAPAccountNumber = 12270286
And DeliveryDateUTC = Convert(Date, GetDate())

Select *
From Mesh.PlannedStop
Where SAPAccountNumber = 12270286
And DeliveryDateUTC = Convert(Date, GetDate())

Select *
From Operation.StoreDelivery
Where SAPAccountNumber = 12270286
And DeliveryDate = Convert(Date, GetDate())

Select Top 1 *
From Staging.ORDER_MASTER
Where CUSTOMER_NUMBER = 12270286


Select Top 1000 *
From Setup.WebAPILog
Where CorrelationID = 'ab3a18ca-2163-41dc-9675-16193795'
Order By LogID DEsc

Select top 100 *
From Mesh.MyDayActivityLog al 
Left Join Setup.WebAPILog pl on al.CorrelationID = pl.CorrelationID
Where RouteID = 106501766
--And WebEndPoint = 'UploadRouteCheckOut'
Order by al.LogID Desc

Select top 100 *
From Mesh.MyDayActivityLog
Where WebEndPoint = 'UploadRouteCheckOut'



Select *
From Mesh.DeliveryRoute
Where RouteID = 111602463
And DeliveryDateUTC = '2019-03-05'

Select *
From 

Select *
From Mesh.MyDayActivityLog
Where DeliveryDateUTC = '2019-03-05'
And GSN = 'SANEX017'
Order by RequestTime desc






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

