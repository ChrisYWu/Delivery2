USE [Merch]
GO
/****** Object:  StoredProcedure [Mesh].[pInsertInvoice]    Script Date: 3/1/2019 10:26:13 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER Proc [Mesh].[pInsertInvoice]
(
	@Headers Mesh.tInvoiceHeaders ReadOnly,
	@Items Mesh.tInvoiceItems ReadOnly,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	Begin Try
		Begin Transaction;
			Delete Mesh.InvoiceItem
			Where RMInvoiceID in 
			(
				Select ci.InvoiceID
				From Mesh.CustomerInvoice ci
				Join @Headers h on ci.RMInvoiceID = h.RMInvoiceID
			)

			Delete ci
			From Mesh.CustomerInvoice ci
			Join @Headers h on ci.RMInvoiceID = h.RMInvoiceID

			Insert Into Mesh.CustomerInvoice(DeliveryDateUTC, RMInvoiceID, RMOrderID, SAPBranchID, SAPAccountNumber, LastModifiedUTC, LastModifiedBy, LocalInsertTime)
			Select DeliveryDateUTC, RMInvoiceID, RMOrderID, SAPBranchID, SAPAccountNumber, @LastModifiedUTC, @LastModifiedBy, GetDate()
			From @Headers
	
			Insert Into Mesh.InvoiceItem(RMInvoiceID, ItemNumber, Quantity, LastModifiedUTC, LastModifiedBy, LocalInsertTime)
			Select RMInvoiceID, ItemNumber, Quantity, @LastModifiedUTC, @LastModifiedBy, GetDate()
			From @Items
			Where Quantity > 0;

			With Temp
			As
			(
				Select RMInvoiceID, Sum(Quantity) TotalQuantity
				From @Items
				Group By RMInvoiceID
			)

			Update ci
			Set TotalQuantity = t.TotalQuantity
			from Mesh.CustomerInvoice ci
			Join Temp t on ci.RMInvoiceID = t.RMInvoiceID

		Commit Transaction;
	End Try
	Begin Catch
		declare @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int;
		select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		rollback transaction;
		raiserror (@ErrorMessage, @ErrorSeverity, @ErrorState);
	End Catch
Go


Select *
From mesh.CustomerInvoice
Where RMInvoiceID = 3516307362

Select *
From mesh.InvoiceItem
Where RMInvoiceID = 3516307362
