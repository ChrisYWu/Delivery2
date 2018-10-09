USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pResetNotification')
Begin
	Drop Proc Notify.pResetNotification
	Print '* Notify.pResetNotification'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc [Notify].[pResetNotification]
(
	@DeliveryDateUTC Date,
	@SAPAccountNumber bigint,
	@PartyID varchar(20)
)
As
Begin
	Set NoCount On;
	Update
	Notify.StoreDeliveryMechandiser
	Set KnownDepartureTime = DepartureTime
	Where DeliveryDateUTC = @DeliveryDateUTC
	And SAPAccountNumber = @SAPAccountNumber
	And PartyID = @PartyID
End

Go

Print 'Notify.pResetNotification created'
Go

exec Notify.pResetNotification @DeliveryDateUTC = '2018-07-20', @SAPAccountNumber = 11278515, @PartyID = 'GSN'
Go
