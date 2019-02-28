USE [Merch]
GO

Drop INDEX NCI_Mesh_InvoiceItem_RMInvoiceID ON Mesh.InvoiceItem
Go

Drop Proc Mesh.pTrimCustomerInvoice
Go

ALTER Proc [Mesh].[pInsertInvoice]
(
	@Headers Mesh.tInvoiceHeaders ReadOnly,
	@Items Mesh.tInvoiceItems ReadOnly,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;
	
	Declare @TotalQuantity int, @InvoiceID int

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
		From Mesh.InvoiceItem 
		Group By RMInvoiceID
	)

	Update ci
	Set TotalQuantity = t.TotalQuantity
	from Mesh.CustomerInvoice ci
	Join Temp t on ci.RMInvoiceID = t.RMInvoiceID
Go
