Use Merch
Go

--Drop Schema Mesh
--Go


IF TYPE_ID(N'Mesh.tEstimatedArrivals') IS Not NULL
Begin
	DROP TYPE Mesh.tEstimatedArrivals
	Print '* Mesh.tEstimatedArrivals'
End

GO

CREATE TYPE Mesh.tEstimatedArrivals AS TABLE(
	DeliveryStopID bigint NOT NULL,
	Sequence Int not null,
	EstimatedArrivalTime DateTime2(0) not null,
	PRIMARY KEY CLUSTERED 
(
	DeliveryStopID ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print 'Mesh.tEstimatedArrivals created'
Go

----------------------------------------------------------
----------------------------------------------------------

IF TYPE_ID(N'Mesh.tDNSStops') IS Not NULL
Begin
	DROP TYPE Mesh.tDNSStops
	Print '* Mesh.tDNSStops'
End

GO

CREATE TYPE Mesh.tDNSStops AS TABLE(
	DeliveryStopID bigint NOT NULL,
	DNSReasonCode varchar(20) null,
	DNSReason varchar(200) null,
	PRIMARY KEY CLUSTERED 
(
	DeliveryStopID ASC
)WITH (IGNORE_DUP_KEY = OFF)
)
GO

Print 'Mesh.tDNSStops created'
Go


------------------------------------------------------------
------------------------------------------------------------
If TYPE_ID(N'Mesh.tInvoiceItems') IS Not NULL
Begin
	Drop Type Mesh.tInvoiceItems
	Print '* Mesh.tInvoiceItems'
End

GO

CREATE TYPE Mesh.tInvoiceItems AS TABLE(
	RMInvoiceID bigint null,
	ItemNumber int NOT NULL,
	Quantity int NOT NULL
)
GO

Print 'Mesh.tInvoiceItems created'
Go


------------------------------------------------------------
------------------------------------------------------------
If TYPE_ID(N'Mesh.tInvoiceHeaders') IS Not NULL
Begin
	Drop Type Mesh.tInvoiceHeaders
	Print '* Mesh.tInvoiceHeaders'
End

GO

CREATE TYPE Mesh.tInvoiceHeaders AS TABLE(
	DeliveryDateUTC date null,
	RMInvoiceID bigint null,
	RMOrderID bigint null,
	SAPBranchID int null,
	SAPAccountNumber int
)
GO

Print 'Mesh.tInvoiceHeaders created'
Go

