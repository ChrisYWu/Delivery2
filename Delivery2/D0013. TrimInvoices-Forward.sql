USE [Merch]
GO

CREATE NONCLUSTERED INDEX NCI_Mesh_InvoiceItem_RMInvoiceID ON Mesh.InvoiceItem
(
	RMInvoiceID ASC
)
Go

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

exec Mesh.pTrimCustomerInvoice @TrimBackDays = 175, @force = 1
Go
Select DeliveryDateUTC, Count(*) cnt
From Mesh.InvoiceItem ii
Join Mesh.CustomerInvoice ci on ii.RMInvoiceID = ci.RMInvoiceID 
Group By DeliveryDateUTC
Order By DeliveryDateUTC
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
	
	exec Mesh.pTrimCustomerInvoice 

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
