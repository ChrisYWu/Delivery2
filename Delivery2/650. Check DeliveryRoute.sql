use Merch
Go

Select StopType StopType1, Sequence,  s.*, a.AccountName
  From Mesh.DeliveryRoute r join 
  Mesh.PlannedStop s on r.DeliveryRouteID = s.DeliveryRouteID
  Left Join  SAP.Account a on s.SAPAccountNumber = a.SAPAccountNumber
Where r.DeliveryDateUTC = '2018-03-19'
And r.RouteID = '112902110'

And s.StopType Not In ('STP', 'B')
Order by StopType

Select *
From SAP.Branch
Where SAPBranchID = '1030'

select *
from sap.route
where saproutenumber = '112902110'



/*
B.    Break
PB.   Paid Break
W.    Wait
PW.   Paid Wait
?     Layover
DPT.  Mid-Route Depot
PL.   Paid Layover

*/

-- B and PB are the same, has service time and not travel to time, Break at the stop just checked out. No Account Number. B is most common.
-- W and PW has both service time and travel to time, but the next stop doesn't have Travel to time, so drive to the next stop and wait there. No Account Number.
-- DPT not sure how to handle it. Observation is large Travel and Service Time. Not neccearily the first stop. Not sure the STP logic will work out. No Account Number, instead sometime the branch ID is there.
-- PL has travel to time, service time and account number. Usage is rear, 1030 - Lenexa is one of them that schedule those routes.


/* 
	Select *
	From ETL.DataLoadingLog
	Go

	Select * 
	From Mesh.DeliveryRoute

	Select * 
	From Mesh.PlannedStop
	Go

	Select *
	From ETL.DataLoadingLog
	Where TableName in ('ORDER_MASTER' , 'ORDER_DETAIL')
	Go

	Select *
	From mesh.CustomerOrder
	Where routeID is null

	Select *
	From mesh.orderitem
	Where Quantity = 0


	Select Distinct RMOrderID
	From Mesh.CustomerOrder

*/
