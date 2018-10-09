USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pGetNotifications')
Begin
	Drop Proc Notify.pGetNotifications
	Print '* Notify.pGetNotifications'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*

*/


Create Proc Notify.pGetNotifications
As
Begin
	Select 
		--Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, DepartureTime), 100), 13, 100) FormattedTime, 
		--DepartureTime, 
		--KnownDepartureTime, 
		--IsEstimated, 
		--DNS, 
		p.PartyID,
		sm.SAPAccountNumber,
		DeliveryDateUTC,
		Phone, 
		--TimeZoneOffSet, 
		--a.AccountName, 
		--A.Address, 
		--A.City, 
		'[' + b.BranchName + ']' + 
		Case 
		When DNS = 1 Then 'The delivery for ' When IsEstimated = 1 Then 'The new estimated delivery for ' Else 'Delivery for ' End 
		--Case When IsEstimated = 1 Then '[Delay Notification:1 Hour Late Or More] The new estimated delivery for ' Else '[Delay Notification:1 Hour Late Or More] Delivery for ' End 
		+
		Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
		+
		Case When DNS = 1 Then 'is canceled'  When IsEstimated = 1 Then 'is ' Else 'is made at ' End 
		+
		Case When DNS = 1 Then '' Else Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, DepartureTime), 100), 13, 100) End MessageBody
	From Notify.StoreDeliveryMechandiser sm
	Join Notify.Party p on sm.PartyID = p.PartyID
	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	Join SAP.Branch b on a.BranchID = b.BranchID
	Where DeliveryDateUTC = Convert(Date, GetDate())
	And (( Delta < -1800 ) Or ( Delta <> 0 And IsEstimated = 0))
	--And DepartureTime < DateAdd(Day, 3, Convert(Date, GetDate()))

End

Go

Print 'Notify.pGetNotifications created'
Go

exec Notify.pGetNotifications
Go



--	Select 
--		p.PartyID,
--		sm.SAPAccountNumber,
--		DeliveryDateUTC,
--		Phone, 
--		Case When IsEstimated = 1 Then 'The new estimated delivery for ' Else 'Delivery for ' End 
--		+
--		Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
--		+
--		Case When IsEstimated = 1 Then 'is ' Else 'is made at ' End 
--		+
--		Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, DepartureTime), 100), 13, 100) MessageBody
--	From Notify.StoreDeliveryMechandiser sm
--	Join Notify.Party p on sm.PartyID = p.PartyID
--	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
--	Where DeliveryDateUTC = Convert(Date, GetDate())

--SELECT p.*
--  FROM [Merch].[Notify].[StoreDeliveryMechandiser] sm
--	Join Notify.Party p on sm.PartyID = p.PartyID
--Where DeliveryDateUTC = Convert(Date, GetDate())

--SELECT *
--  FROM [Merch].[Notify].[StoreDeliveryMechandiser] sm
--Where DeliveryDateUTC = Convert(Date, GetDate())
--And SAPAccountNumber = 11278488

--Select PlannedArrival, ArrivalTime, ServiceTime, ActualServiceTime, *
--From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop
----Where SAPAccountNumber = 11278488
--Where DeliveryDateUTC = Convert(Date, GetDate())
--And ActualServiceTime is not null
--Order By RouteID, Sequence

--Select DeliveryDateUTC, RouteID, Sum(ActualServiceTime)*1.0/Sum(ServiceTime), Case When Sum(ActualServiceTime)*1.0/Sum(ServiceTime) < 1 Then 'Under' Else 'Over' End  
--From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop
----Where SAPAccountNumber = 11278488
--Where ActualServiceTime is not null
--Group by DeliveryDateUTC, RouteID
--Order By DeliveryDAteUTC

--Select *
--From DPSGSHAREDCLSTR.Merch.Mesh.DeliveryStop
--Where RouteID = 112001011
--And DeliveryDateUTC = '2018-08-23'
--Order By Sequence

--Select *
--From SEtup.Person
--Where GSN = 'WADDX005'



--Insert Into Notify.Party
--Select GSN, Phone, Null, 'Merchandiser', -5
--From DPSGSHAREDCLSTR.Merch.Setup.Merchandiser m
--Join DPSGSHAREDCLSTR.Merch.Setup.MerchGroup g on m.MerchGroupID = g.MerchGroupID
--Where g.SAPBranchID = 1120
--And Phone <> ''
--And GSN Not in (Select PartyID From Notify.Party)

--Select *
--From Notify.Party
