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

		Select sm.*,
		p.PartyID, sm.PartyID,
		sm.SAPAccountNumber,
		DeliveryDateUTC,
		Phone, 
		'[' + b.BranchName + ']' + 
		Case 
		When DNS = 1 Then 'The delivery for ' When IsEstimated = 1 Then 'The new estimated delivery for ' Else 'Delivery for ' End 
		+
		Concat(A.AccountName, '(' + Convert(Varchar(12), A.SAPAccountNumber), + ')' + ', ', A.Address, ', ', a.City, ' ')
		+
		Case When DNS = 1 Then 'is canceled'  When IsEstimated = 1 Then 'is ' Else 'is made at ' End 
		+
		Case When DNS = 1 Then '' Else Substring(Convert(varchar(30), DateAdd(Hour, TimeZoneOffSet, DepartureTime), 100), 13, 100) End MessageBody
	From Notify.StoreDeliveryMechandiser sm
	left Join Notify.Party p on sm.PartyID = p.PartyID
	left Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	left Join SAP.Branch b on a.BranchID = b.BranchID
	Where DeliveryDateUTC = Convert(Date, GetDate())
	And (( Delta < -1800 ) Or ( Delta <> 0 And IsEstimated = 0))

	Select *
	From Notify.StoreDeliveryMechandiser
