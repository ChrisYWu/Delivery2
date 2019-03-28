USE [Merch]
GO
/****** Object:  StoredProcedure [Operation].[pGetMerchStoreDelivery]    Script Date: 3/28/2019 11:52:58 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--exec [Operation].[pGetMerchStoreDelivery]
--	@DeliveryDate = '2019-02-27',
--	@SAPAccountNumber = '11303382,11278635,12663640', @IsDetailNeeded = 0,
--	@Debug = 1
--Go

ALTER Proc [Operation].[pGetMerchStoreDelivery]
(
	@DeliveryDate Datetime,
	@SAPAccountNumber varchar(max),
	@IsDetailNeeded bit,
	@Debug bit = 0
)
AS
Begin
	Set NoCount On;

	If (@Debug = 1)
	Begin
		DECLARE @StartTime DateTime2(7)
		Set @StartTime = SYSDATETIME()
		Select '---- Starting ----' Debug, @StartTime StartTime 
	End

	-----------------------------------------------------
	Declare @DeliveryAccount Table
	(
		SAPAccountNumber Int,
		IsMeshDelivery Bit Default 0
	)

	Insert Into @DeliveryAccount(SAPAccountNumber, IsMeshDelivery)
	Select value, 0 From Setup.UDFSplit(@SAPAccountNumber, ',')

	If (@Debug = 1)
	Begin
		Select '---- Populating @DeliveryAccount Before Decorating----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select * From @DeliveryAccount Order By SAPAccountNumber
	End

	Declare @Value varchar(max)

	Select @Value = Value
	From Setup.Config
	Where [Key] = 'MeshEnabledBranches'

	Update da
	Set IsMeshDelivery = 1
	From dbo.udfSplit(@Value, ',') b
	Join SAP.Branch br on b.Value = br.SAPBranchID
	Join SAP.Account a on br.BranchID = a.BranchID
	Join @DeliveryAccount da on a.SAPAccountNumber = da.SAPAccountNumber	
	Where a.Active = 1

	If (@Debug = 1)
	Begin
		Select '---- Populating @DeliveryAccount----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select * From @DeliveryAccount Order By SAPAccountNumber
	End

	-----------------------------------------------------
	
	Declare @TempStoreDelivery Table
	(
		DeliveryDate Datetime,
		ItemDeliveryDate DateTime,
		SAPAccountNumber bigint,
		ItemSAPAccountNumber bigint,
		PlannedArrival datetime,
		ActualArrival datetime,
		ActualDeparture datetime,
		EstimatedArrival datetime Null,
		DriverID nvarchar(50),
		DriverFirstName nvarchar(50),
		DriverLastName nvarchar(50),
		DriverPhone Varchar(50),
		SAPMaterialID Varchar(20),
		Quantity int,	
		Delivered bit,
		DNSReasonCode varchar(20),
		DNSReason varchar(200)
	)

	--Non-mesh -------------------------------------------------------------
	Insert @TempStoreDelivery(DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, DriverID, DriverFirstName, DriverLastName, DriverPhone, 
								SAPMaterialID, Quantity, Delivered)

	Select DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, DriverID, DriverFirstName, DriverLastName, DriverPhone,
		 SAPMaterialID, Quantity, Delivered
	From
	 ( 
	    Select Distinct sd.DeliveryDate, ditem.DeliveryDate as ItemDeliveryDate,  sd.SAPAccountNumber, dItem.SAPAccountNumber as ItemSAPAccountNumber, sd.PlannedArrival, 
		sd.ActualArrival, null ActualDeparture, sd.DriverID, sd.DriverFirstName, sd.DriverLastName, sd.DriverPhone, dItem.SAPMaterialID, dItem.Description, dItem.Quantity, dItem.Delivered, isnull(sd.InvoiceDelivered, 0) InvoiceDelivered 
		From Operation.StoreDelivery sd
		LEFT OUTER JOIN Operation.DeliveryItem dItem
		ON sd.DeliveryDate = dItem.DeliveryDate and sd.SAPAccountNumber = dItem.SAPAccountNumber
		WHERE sd.DeliveryDate = @DeliveryDate			  
		AND sd.SAPAccountNumber in  (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 0)	
			UNION
		Select sd.DeliveryDate, ditem.DeliveryDate as ItemDeliveryDate, sd.SAPAccountNumber, dItem.SAPAccountNumber as ItemSAPAccountNumber, sd.PlannedArrival,
		 sd.ActualArrival, null ActualDeparture, sd.DriverID, sd.DriverFirstName, sd.DriverLastName, sd.DriverPhone, dItem.SAPMaterialID, dItem.Description, dItem.Quantity, dItem.Delivered, isnull(sd.InvoiceDelivered, 0) InvoiceDelivered
		From Operation.StoreDelivery sd
		RIGHT OUTER JOIN Operation.DeliveryItem dItem
		ON dItem.DeliveryDate = sd.DeliveryDate and dItem.SAPAccountNumber = sd.SAPAccountNumber
		WHERE dItem.DeliveryDate = @DeliveryDate
			AND dItem.SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 0)
	 ) 	input
	Where InvoiceDelivered = Delivered
	If (@Debug = 1)
	Begin
		Select '---- Populating @TempStoreDelivery For NON Mesh Delivery----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select Count(*) TotalCnt From @TempStoreDelivery
	End

	---------------------------------------------------------
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$--
	Declare @T Table
	(
		DeliveryDateUTC Date,
		SAPAccountNumber Int,
		ItemNumber Int,
		Quantity int,
		InvoiceQuantity Int Null
	)

	Insert Into @T(DeliveryDateUTC, SAPAccountNumber, ItemNumber, Quantity)
		Select DeliveryDateUTC, SAPAccountNumber, ItemNumber, Sum(Quantity) Quantity
		From Mesh.CustomerOrder co
		Join Mesh.OrderItem oi on co.RMOrderID = oi.RMOrderID
		Where SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 1)	
		And co.DeliveryDateUTC = @DeliveryDate
		Group by DeliveryDateUTC, SAPAccountNumber, ItemNumber
	
	Merge @T As T
	Using (
		Select DeliveryDateUTC, SAPAccountNumber, ItemNumber, Sum(Quantity) Quantity
		From Mesh.CustomerInvoice ci
		Join Mesh.InvoiceItem ii on ci.RMInvoiceID = ii.RMInvoiceID
		Where SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 1)	
		And ci.DeliveryDateUTC = @DeliveryDate
		Group by DeliveryDateUTC, SAPAccountNumber, ItemNumber
	) iv 
	on t.DeliveryDateUTC = iv.DeliveryDateUTC And t.SAPAccountNumber = iv.SAPAccountNumber And t.ItemNumber = iv.ItemNumber
	When Matched Then 
		Update Set T.InvoiceQuantity = iv.Quantity
	When Not Matched By Target Then
	Insert (DeliveryDateUTC, SAPAccountNumber, ItemNumber, Quantity, InvoiceQuantity)
	Values (iv.DeliveryDateUTC, iv.SAPAccountNumber, iv.ItemNumber, iv.Quantity, iv.Quantity);
	---------------------------------------------------------
	If (@Debug = 1)
	Begin
		Select '---- Populating @T The Mesh Delivery, dumping items ----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		--Select * From @T
		Select DeliveryDateUTC, SAPAccountNumber, Count(*) ItemCount From @T Group By DeliveryDateUTC, SAPAccountNumber Order by SAPAccountNumber

		Select '---- Accounts Got Invoices Delivered ----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select Distinct SAPAccountNumber
		From Mesh.CustomerInvoice ci
		Join Mesh.InvoiceItem ii on ci.RMInvoiceID = ii.RMInvoiceID
		Where DeliveryDAteUTC = @DeliveryDate

	End
	--$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$--


	-- Mesh -------------------------------------------------------------
	Declare @MeshHeader Table
	(
		DeliveryDate Datetime,
		SAPAccountNumber bigint,
		PlannedArrival datetime,
		ActualArrival datetime,
		ActualDeparture datetime,
		EstimatedArrival datetime Null,
		DriverID nvarchar(50),
		DriverFirstName nvarchar(50),
		DriverLastName nvarchar(50),
		DriverPhone Varchar(50),
		DNSReasonCode varchar(20),
		DNSReason varchar(200)
	)

	Insert Into @MeshHeader(DeliveryDate, SAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, DNSReasonCode, DNSReason)
	Select DeliveryDate, SAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, DNSReasonCode, DNSReason
	From
	( 
		Select CONVERT(Varchar(10), dr.DeliveryDateUTC, 126) DeliveryDate,
			SAPAccountNumber, 
			PlannedArrival, 
			ds.ArrivalTime ActualArrival, 
			ds.DepartureTime ActualDeparture,
			ds.EstimatedArrivalTime EstimatedArrival,
			dr.ActualStartGSN DriverID, 
			Coalesce(dr.ActualStartFirstName, dr.FirstName) DriverFirstName, 
			Coalesce(dr.ActualStartLastName, dr.LastName) DriverLastName, 
			Coalesce(dr.ActualStartPhoneNumber, dr.PhoneNumber) DriverPhone, 
			ds.DNSReasonCode, ds.DNSReason
		From Mesh.DeliveryRoute dr
		Join Mesh.DeliveryStop ds on dr.DeliveryDateUTC = ds.DeliveryDateUTC And dr.RouteID = ds.RouteID
		Where dr.DeliveryDateUTC = @DeliveryDate
		And (ds.Sequence is null or ds.Sequence > 0)
		And ds.SAPAccountNumber in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 1)	
		And IsAddedByDriver = 1
	) input

	Insert Into @MeshHeader(DeliveryDate, SAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, DNSReasonCode, DNSReason)
	Select DeliveryDate, SAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, DNSReasonCode, DNSReason
	From
	( 
		Select CONVERT(Varchar(10), dr.DeliveryDateUTC, 126) DeliveryDate,
			Coalesce(ps.SAPAccountNumber, ds.SAPAccountNumber) SAPAccountNumber, 
			Coalesce(ps.PlannedArrival, ds.PlannedArrival) PlannedArrival, 
			ds.ArrivalTime ActualArrival, 
			ds.DepartureTime ActualDeparture,
			ds.EstimatedArrivalTime EstimatedArrival,
			dr.ActualStartGSN DriverID, 
			Coalesce(dr.ActualStartFirstName, dr.FirstName) DriverFirstName, 
			Coalesce(dr.ActualStartLastName, dr.LastName) DriverLastName, 
			Coalesce(dr.ActualStartPhoneNumber, dr.PhoneNumber) DriverPhone, 
			ds.DNSReasonCode, ds.DNSReason
		From Mesh.DeliveryRoute dr
		Join Mesh.PlannedStop ps on dr.DeliveryRouteID = ps.DeliveryRouteID
		Left Join Mesh.DeliveryStop ds on dr.DeliveryDateUTC = ds.DeliveryDateUTC And dr.RouteID = ds.RouteID And ps.PlannedStopID = ds.PlannedStopID
		Where dr.DeliveryDateUTC = @DeliveryDate
		And (ds.Sequence is null or ds.Sequence > 0)
		And Coalesce(ps.SAPAccountNumber, ds.SAPAccountNumber) in (Select SAPAccountNumber From @DeliveryAccount Where IsMeshDelivery = 1)	
		And Coalesce(ps.SAPAccountNumber, ds.SAPAccountNumber) Not In (Select SAPAccountNumber From @MeshHeader)
	) 	input

	Insert @TempStoreDelivery(DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, 
								SAPMaterialID, Quantity, Delivered, DNSReasonCode, DNSReason)
	Select DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, ActualDeparture, EstimatedArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone,
			SAPMaterialID, Quantity, Delivered, DNSReasonCode, DNSReason
	From
	( 
		Select CONVERT(Varchar(10), ps.DeliveryDate, 126) DeliveryDate, co.DeliveryDateUTC ItemDeliveryDAte, 
			ps.SAPAccountNumber SAPAccountNumber, 
			co.SAPAccountNumber ItemSAPAccountNumber, 
			PlannedArrival, 
			ActualArrival, 
			ActualDeparture,
			EstimatedArrival,
			DriverID, 
			DriverFirstName, 
			DriverLastName, 
			DriverPhone, 
			co.ItemNumber SAPMaterialID, co.Quantity, Case When co.InvoiceQuantity is null Then 0 Else 1 End As Delivered,
			DNSReasonCode, DNSReason
		From @MeshHeader ps
		Left Join @T co on ps.SAPAccountNumber = co.SAPAccountNumber And co.DeliveryDateUTC = ps.DeliveryDate
		Where ps.DeliveryDate = @DeliveryDate
	) 	input

	If (@Debug = 1)
	Begin
		Select '---- Populating @TempStoreDelivery For MESH Delivery done.---' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select Count(*) TotalCnt From @TempStoreDelivery

		Select '---- Dumping @TempStoreDelivery.---' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select *
		From @TempStoreDelivery

		Select '---- Dumping @Mesh Header---' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select *
		From @MeshHeader
	End

	Select Distinct 
		(Case When (DeliveryDate Is Null) Then CONVERT(Varchar(10), ItemDeliveryDate, 126)  Else CONVERT(Varchar(10), DeliveryDate, 126)  End) DeliveryDate,	
		(Case When (SAPAccountNumber Is Null) Then ItemSAPAccountNumber Else SAPAccountNumber End) SAPAccountNumber
		,PlannedArrival
		,ActualArrival
		,ActualDeparture
		,EstimatedArrival
		,DriverID
		,DriverFirstName
		,DriverLastName
		,DriverPhone
		,DNSReasonCode, DNSReason
	From @TempStoreDelivery	

	IF (@IsDetailNeeded = 1)
	BEGIN
		Select tsd.ItemSAPAccountNumber AS SAPAccountNumber, tsd.SAPMaterialID, tsd.Quantity, tsd.Delivered
		From @TempStoreDelivery tsd 
		Where tsd.ItemDeliveryDate Is not Null
		And Quantity > 0
	END
	
	If (@Debug = 1)
	Begin
		Select '---- Select from @TempStoreDelivery done----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
	End

End
Go

Print 'ETL.pLoadDeliveryForToday altered'
Go

Select *
From Mesh.DeliveryStop
