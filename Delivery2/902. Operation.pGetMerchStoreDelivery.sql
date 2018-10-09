USE [Merch]
GO
/****** Object:  StoredProcedure [Operation].[pGetMerchStoreDelivery]    Script Date: 4/6/2017 9:52:39 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
	Exec Operation.pGetMerchStoreDelivery '2016-08-04', '11227481'

	Exec Operation.pGetMerchStoreDelivery '2016-07-26', '11227731,11228435,11228560', 1
	Exec Operation.pGetMerchStoreDelivery '2016-07-26', '11227380', 1

	Testing Scenarios

	(1) DeliveryItems have data but not in StoreDelivery

	Exec Operation.pGetMerchStoreDelivery '2016-07-23', '11275142,11276878,11930741', 1

	Select * from Operation.DeliveryItem where SAPAccountNumber in (11275142,11276878,11930741) and deliveryDate = '2016-07-23'
	Select * from Operation.StoreDelivery where SAPAccountNumber in (11275142,11276878,11930741) and deliveryDate = '2016-07-23'

	(2) StoreDelivery have data but not in DeliveryItems

	Exec Operation.pGetMerchStoreDelivery '2016-07-23', '11228306', 1

	Select * from Operation.DeliveryItem where SAPAccountNumber in (11228306) and deliveryDate = '2016-07-23'
	Select * from Operation.StoreDelivery where SAPAccountNumber in (11228306) and deliveryDate = '2016-07-23'

	(3) StoreDelivery and DeliveryItems have data

	Exec Operation.pGetMerchStoreDelivery '2016-07-23', '11227583, 11227704, 11227799', 1

	Select * from Operation.DeliveryItem where SAPAccountNumber in (11227583, 11227704, 11227799) and deliveryDate = '2016-07-23'
	Select * from Operation.StoreDelivery where SAPAccountNumber in (11227583, 11227704, 11227799) and deliveryDate = '2016-07-23'

*/

--ALTER Proc [Operation].[pGetMerchStoreDelivery]
(
	@DeliveryDate Datetime,
	@SAPAccountNumber Varchar(4000),
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

	Declare @TempStoreDelivery Table
	(
		DeliveryDate Datetime,
		ItemDeliveryDate DateTime,
		SAPAccountNumber bigint,
		ItemSAPAccountNumber bigint,
		PlannedArrival datetime,
		ActualArrival datetime,
		DriverID nvarchar(50),
		DriverFirstName nvarchar(50),
		DriverLastName nvarchar(50),
		DriverPhone Varchar(50),
		SAPMaterialID Varchar(20),
		Quantity int,	
		Delivered bit
	)

	Insert @TempStoreDelivery(DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone, 
								SAPMaterialID, Quantity, Delivered)

	Select DeliveryDate, ItemDeliveryDate, SAPAccountNumber, ItemSAPAccountNumber, PlannedArrival, ActualArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone,
		 SAPMaterialID, Quantity, Delivered

	From
	 ( 
	     Select Distinct sd.DeliveryDate, ditem.DeliveryDate as ItemDeliveryDate,  sd.SAPAccountNumber, dItem.SAPAccountNumber as ItemSAPAccountNumber, sd.PlannedArrival, 
		 sd.ActualArrival, sd.DriverID, sd.DriverFirstName, sd.DriverLastName, sd.DriverPhone, dItem.SAPMaterialID, dItem.Description, dItem.Quantity, dItem.Delivered, isnull(sd.InvoiceDelivered, 0) InvoiceDelivered 
		 From Operation.StoreDelivery sd
		 LEFT OUTER JOIN Operation.DeliveryItem dItem
		 ON sd.DeliveryDate = dItem.DeliveryDate and sd.SAPAccountNumber = dItem.SAPAccountNumber
		 WHERE sd.DeliveryDate = @DeliveryDate			  
			AND sd.SAPAccountNumber in  (Select value  From Setup.UDFSplit(@SAPAccountNumber, ','))	

		 UNION


		Select sd.DeliveryDate, ditem.DeliveryDate as ItemDeliveryDate, sd.SAPAccountNumber, dItem.SAPAccountNumber as ItemSAPAccountNumber, sd.PlannedArrival,
		 sd.ActualArrival, sd.DriverID, sd.DriverFirstName, sd.DriverLastName, sd.DriverPhone, dItem.SAPMaterialID, dItem.Description, dItem.Quantity, dItem.Delivered, isnull(sd.InvoiceDelivered, 0) InvoiceDelivered
		From Operation.StoreDelivery sd
		RIGHT OUTER JOIN Operation.DeliveryItem dItem
		ON dItem.DeliveryDate = sd.DeliveryDate and dItem.SAPAccountNumber = sd.SAPAccountNumber
		WHERE dItem.DeliveryDate = @DeliveryDate
			AND dItem.SAPAccountNumber in (Select value  From Setup.UDFSplit(@SAPAccountNumber, ','))

	 ) 	input
	 Where InvoiceDelivered = Delivered

	If (@Debug = 1)
	Begin
		Select '---- Creating @TempStoreDelivery----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
	End

	If (@Debug = 1)
	Begin
		Select '---- Insert data in #storeDelivery Table done----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		
		Select * From @TempStoreDelivery
	End


	Select  Distinct 
		(Case When (DeliveryDate Is Null) Then CONVERT(Varchar(10), ItemDeliveryDate, 126)  Else CONVERT(Varchar(10), DeliveryDate, 126)  End) DeliveryDate,	
		(Case When (SAPAccountNumber Is Null) Then ItemSAPAccountNumber Else SAPAccountNumber End) SAPAccountNumber
		,PlannedArrival, ActualArrival, DriverID, DriverFirstName, DriverLastName, DriverPhone 
	From @TempStoreDelivery	
	Where Quantity > 0
	
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

	Exec Operation.pGetMerchStoreDelivery '2018-07-02', '11278536,11290773,11278515,11278537,11278538,11278517', 0
