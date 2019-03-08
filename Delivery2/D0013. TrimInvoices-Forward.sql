USE [Merch]
GO

CREATE NONCLUSTERED INDEX NCI_Mesh_InvoiceItem_RMInvoiceID ON Mesh.InvoiceItem
(
	RMInvoiceID ASC
)
Go

CREATE NONCLUSTERED INDEX NCI_Mesh_Invoice_RMInvoiceID ON Mesh.CustomerInvoice
(
	RMInvoiceID ASC
)
Go

-------------------------------------------------------------
-------------------------------------------------------------
Create Proc Mesh.pTrimCustomerInvoice
(
	@TrimBackDays Int = 2,
	@Force Bit = 0
)
AS
Begin
	If (@Force = 1 Or (DatePart(MINUTE, SYSDATETIME()) Between 29 And 31))
	Begin
		Declare @CutOffDate Date
		Set @CutOffDate = DateAdd(Day, -1 * @TrimBackDays, Convert(Date, SysUTCDateTime()))

		Select @CutOffDate CutOffDate

		Delete Mesh.InvoiceItem
		Where RMInvoiceID In (
			Select Distinct RMInvoiceID
			From Mesh.CustomerInvoice With (NoLock)
			Where DeliveryDateUTC < @CutOffDate 
		)

		Delete
		From Mesh.CustomerInvoice
		Where DeliveryDateUTC < @CutOffDate 
	End
End
Go

-------------------------------------------------------------
-------------------------------------------------------------

exec Mesh.pTrimCustomerInvoice @TrimBackDays = 175, @force = 1
Go
Select DeliveryDateUTC, Count(*) cnt
From Mesh.InvoiceItem ii with (nolock)
Join Mesh.CustomerInvoice ci with (nolock) on ii.RMInvoiceID = ci.RMInvoiceID 
Group By DeliveryDateUTC
Order By DeliveryDateUTC
Go

-------------------------------------------------------------
-------------------------------------------------------------
ALTER Proc [Mesh].[pInsertInvoice]
(
	@Headers Mesh.tInvoiceHeaders ReadOnly,
	@Items Mesh.tInvoiceItems ReadOnly,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	exec Mesh.pTrimCustomerInvoice 

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


-----------------------------------------------
-----------------------------------------------
;
With CTE As 
(
	Select Top 1 RMInvoiceID, ItemNumber, Quantity, LastModifiedBy, Count(*) Cnt, Max(InvoiceItemID) InvoiceItemID
	From Mesh.InvoiceItem With (nolock)
	Group By RMInvoiceID, ItemNumber, Quantity, LastModifiedBy
)

Delete Mesh.InvoiceItem 
Where InvoiceItemID Not In (Select InvoiceItemID From CTE)
Go

Delete 
From Mesh.CustomerInvoice 
Where InvoiceID Not In 
(
	Select InvoiceID From
		(
		Select RMInvoiceID, count(*) Cnt, Max(InvoiceID) InvoiceID
		From Mesh.CustomerInvoice ii With (nolock)
		Group By RMInvoiceID
		) a
)
Go

Select count(*)
From Mesh.InvoiceItem
Go

Select DeliveryDateUTC, count(*) Cnt
From Mesh.CustomerInvoice
Group By DeliveryDateUTC
Go

Select GetDate()
exec Mesh.pTrimCustomerInvoice @Force = 1
Go

