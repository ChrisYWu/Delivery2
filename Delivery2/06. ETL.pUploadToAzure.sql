use DSDDelivery
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('ETL.pUploadToAzure'))
Begin
	Drop Proc ETL.pUploadToAzure
	Print '* ETL.pUploadToAzure'
End
Go

/*
--exec ETL.pUploadToAzure

*/

Create Proc ETL.pUploadToAzure
As
	Set NoCount On;
	
	Declare @DeliveryDate Date
	Declare @LocalDeliveryDate Date

	Select @DeliveryDate = Max(DeliveryDate)
	From AzureDeliveryTime.DeliveryTime.Operation.Delivery

	Select @LocalDeliveryDate = Max(DeliveryDate)
	From Operation.Delivery

	If (IsNull(@LocalDeliveryDate, '1753-1-1') > IsNull(@DeliveryDate, '1753-1-1'))
	Begin
		Delete From AzureDeliveryTime.DeliveryTime.Archive.Delivery
		Where DeliveryDate >= @DeliveryDate

		Insert Into AzureDeliveryTime.DeliveryTime.Archive.Delivery
		Select * From AzureDeliveryTime.DeliveryTime.Operation.Delivery

		Delete From AzureDeliveryTime.DeliveryTime.Operation.Delivery

		Insert Into AzureDeliveryTime.DeliveryTime.Operation.Delivery
		Select * From Operation.Delivery
	End

Go

Print 'Creating ETL.pUploadToAzure'
Go

