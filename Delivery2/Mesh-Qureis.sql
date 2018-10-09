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
and DeliveryDateUTC = '2018-07-02'
and RouteID = 112001013
Order by coalesce(l.RequestTime, e.ServerInsertTime) Desc

Exec Mesh.pGetDeliveryManifest @RouteID = 112002021, @DeliveryDateUTC = '112002201'

exec ETL.pLoadOrderPeriodically
exec ETL.pLoadDeliverySchedulePeriodically

Select LastManifestFetched, *
From Mesh.Deliveryroute
Where DeliveryDAteUTC = '2018-06-28'
And RouteID like '1120%'
--And TotalQuantity > 0
Order by RouteID


Select *
From Mesh.CustomerInvoice

Select *
From Mesh.InvoiceItem

Select *
From Mesh.PlannedStop
Where DeliveryDAteUTC = '2018-07-02'
--And RouteID = 112002012
And RouteID like '112002201%'
Order By Sequence


Select * From Mesh.DeliveryStop
Where  DeliveryDAteUTC = '2018-06-27'
Order By Sequence

select *
from sap.account
where sapaccountnumber = '11278536'





/*
2175
2177
2178
2173
2180
2172
2176
2174
2179
*/


/*
Select *
From Mesh.DeliveryStop
Where DeliveryDateUTC = '2018-05-22'
and RouteID = 111501304
Order By Sequence

Select *
From Mesh.Resequence
Where ResequenceID = 144

select *
From Mesh.ResequenceDetail
Where ResequenceID = 144
Order by Sequence

select *
From Mesh.ResequeceReasons
Where ResequenceID = 144

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = '2018-05-21'
and RouteID = 111501304


Select *
From mesh.DeliveryStop
Where RouteID = 111501304
And DeliveryDateUtc = '2018-05-21'
Order By Sequence


Select *
From mesh.DeliveryStop
Where DeliveryStopID = 1755


-- EstimatedDeparture = AcutalArrival(checkin) + SErviceTime

--Select top 100 *
--From Mesh.MyDayActivityLog
--Order By LogID Desc

--Select top 100 *
--From Setup.WebAPILog
--Order By LogID Desc


-- Check header ---
Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = Convert(Date, GetDate())  --'2018-04-16'
And RouteID = 111501301

-- Check Details ---
Select a.SAPAccountNumber, a.AccountName, s.*
From Mesh.DeliveryStop s
left Join SAP.Account a on s.SAPAccountNumber = a.SAPAccountNumber
Where DeliveryDateUTC = Convert(Date, GetDate())  
And RouteID = 111501301
Order By Sequence

Select *
From SAP.Account
Where SAPAccountNumber = '12628382'


--- Plan ---
Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = Convert(Date, GetDate())  --'2018-04-16'
And RouteID = 111501301
Order By Sequence
*/