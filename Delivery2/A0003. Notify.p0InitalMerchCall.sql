USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'p0InitialMerchCall')
Begin
	Drop Proc Notify.p0InitialMerchCall
	Print '* Notify.p0InitialMerchCall'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc Notify.p0InitialMerchCall
As

	Delete Notify.StoreDeliveryMechandiser 
	Where DeliveryDateUTC = Convert(Date, GetDate())

	-- Distinct to avoid multiple assign --
	Insert Into Notify.StoreDeliveryMechandiser(DeliveryDAteUTC, SAPAccountNumber, PartyID, DepartureTime, KnownDepartureTime, DNS, IsEstimated)
	Select Distinct d.DispatchDate, d.SAPAccountNumber,  
			d.GSN, 
			--Case When d.GSN in ('LEAWG001', 'HAWAX504') Then 'WUXYX001' Else d.GSN End GSN, 
			--'BINNX001' GSN, 
			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
				DateAdd(second, ds.ServiceTime, ds.PlannedArrival), 
				DateAdd(second, ps.ServiceTime, ps.PlannedArrival)) DepartueTime, 
			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
			DateAdd(second, ds.ServiceTime, ds.PlannedArrival), 
			DateAdd(second, ps.ServiceTime, ps.PlannedArrival)) KnownDepartueTime, 0 DNS,
		Case When ds.CheckOutTime is null Then 1 Else 0 End IsEstimated 
	From DPSGSHAREDCLSTR.Merch.Planning.Dispatch d
	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup m on d.MerchGroupID = m.MerchGroupID
	Left Join DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds on d.SAPAccountNumber = ds.SAPAccountNumber and ds.DeliveryDateUTC = d.DispatchDate
	Left Join DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop ps on d.SAPAccountNumber = ps.SAPAccountNumber and ps.DeliveryDateUTC = d.DispatchDate
	Where SAPBranchID in(1120, 1138, 1178)
	And DispatchDate = Convert(Date, GetDate())
	And InvalidatedBatchID is null

	Delete Notify.StoreDeliveryMechandiser
	Where DeliveryDAteUTC = Convert(Date, GetDate())
	And DepartureTime is Null

	-- Distinct to avoid multiple trace --
	Insert Into Notify.StoreDeliveryTimeTrail
		(DeliveryDateUTC
		,SAPAccountNumber
		,DepartureTime
		,IsEstimated, DNS
		,ReportTimeLocal)
	Select Distinct DeliveryDateUTC, SAPAccountNumber, DepartureTime, IsEstimated, DNS, GetDate() 
	From Notify.StoreDeliveryMechandiser
	Where DeliveryDateUTC = Convert(Date, GetDate())

Go

Print 'Notify.p0InitialMerchCall created'
Go

--exec Notify.p0InitialMerchCall
--Go
