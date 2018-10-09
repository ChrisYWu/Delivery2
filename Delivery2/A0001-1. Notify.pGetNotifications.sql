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
		Distinct p.PartyID GSN	
		--Distinct p.PartyID,
		--0 as SAPAccountNumber,
		--,Convert(Date, GetDate()) DeliveryDateUTC,
		,p.Phone, FirstName + ' ' + LastName Merchandiser	
		--'Hi, ' + dbo.udf_TitleCase(RTrim(LTrim(pr.FirstName))) +  ': Input needed, please click the link to complete the survey about the delivery notifications. Thanks! https://www.surveymonkey.com/r/6XQ58RT' MessageBody
	From Notify.StoreDeliveryMechandiser sm
	Join Notify.Party p on sm.PartyID = p.PartyID
	Join DPSGSharedClstr.Merch.Setup.Person pr on p.PartyID = pr.GSN
	Join SAP.Account a on sm.SAPAccountNumber = a.SAPAccountNumber
	Where DeliveryDateUTC > '2018-08-22'
	Order By Merchandiser


End

Go

Print 'Notify.pGetNotifications created'
Go

exec Notify.pGetNotifications
Go



