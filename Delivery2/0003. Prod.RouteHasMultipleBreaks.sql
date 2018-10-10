Use Merch
Go

Select DeliveryDateUTC, RouteID, Count(*)
From Mesh.PlannedStop
Where StopType <> 'STP'
And RouteID like '1104%'
Group by DeliveryDateUTC, RouteID
Having Count(*) > 2
Order By DeliveryDateUTC Desc, RouteID

Select *
From Mesh.PlannedStop
Where DeliveryDateUTC = '2018-10-11'
And RouteID = 110402740
Order By Sequence

Select *
From SAP.Branch
Where SAPBranchID = '1104'

