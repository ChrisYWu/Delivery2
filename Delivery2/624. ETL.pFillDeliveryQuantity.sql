USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pFillDeliveryQuantity')
Begin
	Drop Proc ETL.pFillDeliveryQuantity
	Print '* ETL.pFillDeliveryQuantity'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec ETL.pFillDeliveryQuantity

*/

Create Proc ETL.pFillDeliveryQuantity
As
	-----Update pre-calculated case quantities ------
	-----Might need to remove the RouteID from join clause, because sometimes they are not consistent
	Update ps
	Set Quantity = TotalQuantity, OrderCountLastUpdatedLocalTime = SysDateTime()
	From Mesh.PlannedStop ps
	Join (
		Select co.DeliveryDateUTC, co.RouteID, co.SAPAccountNumber, Sum(Quantity) TotalQuantity
		From Mesh.CustomerOrder co
		Join Mesh.OrderItem i on co.RMOrderID = i.RMOrderID
		And co.DeliveryDateUTC >= Convert(Date, DateAdd(day, -1, GetUTCDate()))
		Group By co.DeliveryDateUTC, co.RouteID, co.SAPAccountNumber
	) co on ps.DeliveryDateUTC = co.DeliveryDateUTC and ps.SAPAccountNumber = co.SAPAccountNumber
	Where Quantity != TotalQuantity
	And 
	Not (ps.RouteID In 
			(
				111501301
				,111501302
				,111501303
				,111501304
			)
	)
	--) co on ps.DeliveryDateUTC = co.DeliveryDateUTC and ps.RouteID = co.RouteID and ps.SAPAccountNumber = co.SAPAccountNumber
	-- This will introduce some inconsistency

	--- Not join orders and summing, but join delivery and summing to avoid inconsistency
	Update dr
	Set TotalQuantity = ds.TotalQuantity, OrderCountLastUpdatedLocalTime = SysDateTime()
	From Mesh.DeliveryRoute dr
	Join (
		Select dr.DeliveryRouteID, sum(Quantity) TotalQuantity
		From Mesh.DeliveryRoute dr
		Join Mesh.PlannedStop ps on dr.DeliveryRouteID = ps.DeliveryRouteID
		Group By dr.DeliveryRouteID
	) ds on dr.DeliveryRouteID = ds.DeliveryRouteID
	Where dr.TotalQuantity != ds.TotalQuantity
	And 
	Not (dr.RouteID In 
			(
				111501301
				,111501302
				,111501303
				,111501304
			)
	)

Go

Print 'ETL.pFillDeliveryQuantity created'
Go
