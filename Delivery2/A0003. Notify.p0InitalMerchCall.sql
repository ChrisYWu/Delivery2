USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'p0InitialMerchCall')
Begin
	Drop Proc Notify.p0InitialMerchCall
	Print '* Notify.p0InitialMerchCall'
End 
Go

--Select Distinct PartyID
--From Notify.StoreDeliveryMechandiser
--Where DeliveryDAteUTC = Convert(Date, GetDate())
--And SAPBranchID = 1103

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc Notify.p0InitialMerchCall
As
	-- Get the latest party
	Merge [Notify].[Party] as tar
	Using (
	Select m.GSN, p.Firstname, p.LastName, m.Phone, Null Email, 'Merchandiser' Role, 
		(Case When SAPBranchID = 1120 Then -6 
			  When SAPBranchID = 1116 Then -6
			  When SAPBranchID = 1178 Then -6
			  When SAPBranchID = 1103 Then -7
			  When SAPBranchID = 1104 Then -7
			  When SAPBranchID = 1138 Then -8 End) TimeZoneOffSet, SAPBranchID
	From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup mg on m.MerchGroupID = mg.MerchGroupID
	Join DPSGSHAREDCLSTR.Merch.Setup.Person p on m.GSN = p.GSN 
	Where SAPBranchID in (1103, 1104, 1120, 1138, 1178)
	And M.Phone <> '') Input 
	On Tar.PartyID = input.GSN
	When Matched
	Then Update
	SEt Tar.Phone = input.Phone, Tar.TimeZoneOffSet = input.TimeZoneOffset
	When Not Matched
	Then Insert([PartyID]
			,[Phone]
			,[Role]
			,[TimeZoneOffset])
			Values(input.GSN, input.Phone, input.Role, input.TimeZoneOffset);
	---------------------------

	Delete Notify.StoreDeliveryMechandiser 
	Where DeliveryDateUTC = Convert(Date, GetDate())

	-- Distinct to avoid multiple assign --
	Insert Into Notify.StoreDeliveryMechandiser(DeliveryDAteUTC, SAPAccountNumber, PartyID, DepartureTime, KnownDepartureTime, DNS, IsEstimated, SAPBranchID)
	Select Distinct d.DispatchDate, d.SAPAccountNumber,  
			d.GSN, 
			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
				DateAdd(second, ds.ServiceTime, ds.PlannedArrival), 
				DateAdd(second, ps.ServiceTime, ps.PlannedArrival)) DepartueTime, 
			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
			DateAdd(second, ds.ServiceTime, ds.PlannedArrival), 
			DateAdd(second, ps.ServiceTime, ps.PlannedArrival)) KnownDepartueTime, 0 DNS,
		Case When ds.CheckOutTime is null Then 1 Else 0 End IsEstimated, m.SAPBranchID 
	From DPSGSHAREDCLSTR.Merch.Planning.Dispatch d
	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup m on d.MerchGroupID = m.MerchGroupID
	Left Join DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds on d.SAPAccountNumber = ds.SAPAccountNumber and ds.DeliveryDateUTC = d.DispatchDate
	Left Join (
		Select DeliveryDateUTC, SAPAccountNumber, Min(PlannedArrival) PlannedArrival, Sum(ServiceTime) ServiceTime
		From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop ps 
		Where DeliveryDateUTC = Convert(Date, GetDate())
		Group By DeliveryDateUTC, SAPAccountNumber
	) ps on d.SAPAccountNumber = ps.SAPAccountNumber and ps.DeliveryDateUTC = d.DispatchDate
	Where SAPBranchID in(1103, 1104, 1116, 1120, 1138, 1178)
	And DispatchDate = Convert(Date, GetDate())
	And (ds.Sequence Is NUll OR ds.Sequence > 0)
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

--Select *
--From Notify.StoreDeliveryTimeTrail

--Select *
--From Notify.StoreDeliveryMechandiser

--Select *
--From SAP.Branch
--Where SAPBranchID = '1178'

/*
Msg 2627, Level 14, State 1, Line 48
Violation of PRIMARY KEY constraint 'PK_StoreDeliveryMechandiser'. Cannot insert duplicate key in object 'Notify.StoreDeliveryMechandiser'. The duplicate key value is (2018-10-30, 11278532, RADRJ001).
*/

--	Select Distinct d.DispatchDate, d.SAPAccountNumber,  
--			d.GSN, 
--			--Case When d.GSN in ('LEAWG001', 'HAWAX504') Then 'WUXYX001' Else d.GSN End GSN, 
--			--'BINNX001' GSN, 
--			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
--				DateAdd(second, ds.ServiceTime, ds.PlannedArrival), 
--				DateAdd(second, ps.ServiceTime, ps.PlannedArrival)) DepartueTime, 
--			Coalesce(ds.CheckOutTime, ds.EstimatedDepartureTime, 
--			DateAdd(second, ds.ServiceTime, ds.PlannedArrival), 
--			DateAdd(second, ps.ServiceTime, ps.PlannedArrival)) KnownDepartueTime, 0 DNS,
--		Case When ds.CheckOutTime is null Then 1 Else 0 End IsEstimated 
--	From DPSGSHAREDCLSTR.Merch.Planning.Dispatch d
--	Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup m on d.MerchGroupID = m.MerchGroupID
--	Left Join DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop ds on d.SAPAccountNumber = ds.SAPAccountNumber and ds.DeliveryDateUTC = d.DispatchDate
--	Left Join 
--	(
--		Select DeliveryDateUTC, SAPAccountNumber, Min(PlannedArrival) PlannedArrival, Sum(ServiceTime) ServiceTime
--		From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop ps 
--		Where DeliveryDateUTC = Convert(Date, GetDate())
--		And SAPAccountNumber = 11278532
--		Group By DeliveryDateUTC, SAPAccountNumber
--	) ps on d.SAPAccountNumber = ps.SAPAccountNumber and ps.DeliveryDateUTC = d.DispatchDate
--	Where SAPBranchID in(1120, 1138, 1178)
--	And DispatchDate = Convert(Date, GetDate())
--	And InvalidatedBatchID is null
--	And ds.SAPAccountNumber = 11278532

/*
Msg 2627, Level 14, State 1, Procedure p0InitialMerchCall, Line 36 [Batch Start Line 93]
Violation of PRIMARY KEY constraint 'PK_StoreDeliveryMechandiser'. Cannot insert duplicate key in object 'Notify.StoreDeliveryMechandiser'. The duplicate key value is (2018-10-30, 12316802, WEIDL001).
*/

--SElect *
--From DPSGSHAREDCLSTR.Merch.Mesh.PlannedStop
--Where DeliveryDateUTC = Convert(Date, GetDate())
--And SAPAccountNumber = 12316802

--SElect *
--From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop
--Where DeliveryDateUTC = Convert(Date, GetDate())
--And SAPAccountNumber = 12316802
