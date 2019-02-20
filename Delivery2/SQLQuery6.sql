use Merch
Go

Select *
From Mesh.DeliveryRoute
Where RouteID = 111502703
order by DeliveryDateUTC desc

Select *
From SAP.Route
Where SAPRouteNumber = 111502701

Select *
From SAP.Branch
Where BranchID = 161

Select *
From Mesh.DeliveryRoute
Where DeliveryDateUTC = '2019-02-21'
And RouteID = 111502703

Select *
From Mesh.PlannedStop
Where RouteID = 111502703
And DeliveryDateUTC = '2019-02-21'
Order By [Sequence];

-------------------------
With Stp As
(
Select *
From Mesh.PlannedStop
Where RouteID = 111502703
And DeliveryDateUTC = '2019-02-21'
)

Select *
From Mesh.CustomerOrder
Where DeliveryDateUTC = '2019-02-21' 
And SAPAccountNumber in (Select Distinct SAPAccountNumber From Stp)




