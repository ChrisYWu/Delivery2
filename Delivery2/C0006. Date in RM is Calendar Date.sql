Select Start_Time, count(*)
FROM [Merch].[Staging].[RS_ROUTE]
Group By Start_Time
Order By Start_Time

Select *
From Mesh.DeliveryRoute
Where PlannedStartTime = '2018-11-30 01:00:00'
And RouteID = 112701630

Select *
From Mesh.PlannedStop
Where RouteID = 112701630
And DeliveryDateUTC = '2018-11-30'
Order By [Sequence]

-------------------------
With Stp As
(
Select *
From Mesh.PlannedStop
Where RouteID = 112701630
And DeliveryDateUTC = '2018-11-30'
)

Select *
From Mesh.CustomerOrder
Where DeliveryDateUTC = '2018-11-29' 
And SAPAccountNumber in (Select Distinct SAPAccountNumber From Stp)




Select *
From SAP.Branch
Where SAPBranchID = '1127'

Select SYSDATETIME(), SYSDATETIMEOFFSET()


