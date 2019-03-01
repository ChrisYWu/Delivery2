use Merch
Go

Select DeliveryDateUTC, count(*)
From Mesh.InvoiceItem ii With (nolock)
Join (Select Distinct RMInvoiceID, DeliveryDAteUTC From Mesh.CustomerInvoice with (nolock)) ci on ii.RMInvoiceID = ci.RMInvoiceID
Group By DeliveryDateUTC

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

