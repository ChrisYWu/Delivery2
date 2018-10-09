USE [Merch]
GO

If Exists (Select * From sys.procedures Where Name = 'pLoadOrderPeriodically')
Begin
	Drop Proc ETL.pLoadOrderPeriodically
	Print '* ETL.pLoadOrderPeriodically'
End 
Go


/****** Object:  StoredProcedure [ETL].[pLoadOrderItemsFromRM]    Script Date: 1/23/2018 3:45:55 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec ETL.pLoadOrderItemsFromRM

exec ETL.pLoadOrderItemsFromRM @DispatchDate = '2016-07-19'

*/

Create Proc [ETL].pLoadOrderPeriodically
(
	@DispatchDate Datetime = null
)
As
	SET NOCOUNT ON;  
	Declare @Query varchar(1024)

	If @DispatchDate is null
		Set @DispatchDate = GetDate()

	--- Order Details ---
	/*
	SELECT OM.LOCATION_ID SALESOFFICE_ID, OM.CUSTOMER_NUMBER ACCOUNT_NUMBER, OM.DELIVERYDATE DELIVERY_DATE, 
		OM.ORDERSTATUS ORDSTATUS, OD.ITEM_NUMBER, IM.PRINTOUT_DESCRIPTION ITEM_DESCRIPTION, 
		SUM(OD.CASEQTY) DELIVERYCASEQTY 
	FROM ORDER_MASTER OM, ORDER_DETAIL OD, ITEM_MASTER IM 
	WHERE TO_CHAR(OM.DELIVERYDATE, 'DD-MM-YY') = '16-06-16' 
	AND OM.ORDERSTATUS IN (2,3,4) 
	AND OM.ORDER_NUMBER = OD.ORDER_NUMBER 
	AND OD.TYPE = 'O' 
	AND OD.ITEM_NUMBER = IM.ITEM_NUMBER 
	AND OM.LOCATION_ID = IM.LOCATION_ID 
	GROUP BY OM.LOCATION_ID, OM.CUSTOMER_NUMBER , OM.DELIVERYDATE , OM.ORDERSTATUS , OD.ITEM_NUMBER, IM.PRINTOUT_DESCRIPTION 

	*/
	--- 2 mins 13 seconds, 13 K results ---
	Truncate Table Staging.RMPlanedDeliveryItems 

	Set @Query = 'Insert Into Staging.RMPlanedDeliveryItems Select * From OpenQuery(' 
	Set @Query += 'RM' +  ', ''';
	Set @Query += 'SELECT OM.LOCATION_ID SALESOFFICE_ID, OM.CUSTOMER_NUMBER ACCOUNT_NUMBER, OM.DELIVERYDATE DELIVERY_DATE, 
					OM.ORDERSTATUS ORDSTATUS, OD.ITEM_NUMBER, IM.PRINTOUT_DESCRIPTION ITEM_DESCRIPTION, 
					SUM(OD.CASEQTY) DELIVERYCASEQTY 
					FROM ACEUSER.ORDER_MASTER OM, ACEUSER.ORDER_DETAIL OD, ACEUSER.ITEM_MASTER IM 
					WHERE TO_CHAR(OM.DELIVERYDATE, ''''YYYY-MM-DD'''') = ';
	Set @Query += ' ' + dbo.[udfConvertToPLSqlTimeFilter](@DispatchDate)
	Set @Query += ' AND OM.ORDERSTATUS IN (2,3,4) 
					AND OM.ORDER_NUMBER = OD.ORDER_NUMBER 
					AND OD.TYPE in ( ''''O'''', ''''F'''' )
					AND OD.ITEM_NUMBER = IM.ITEM_NUMBER 
					AND OM.LOCATION_ID = IM.LOCATION_ID 
					GROUP BY OM.LOCATION_ID, OM.CUSTOMER_NUMBER , OM.DELIVERYDATE , OM.ORDERSTATUS , OD.ITEM_NUMBER, IM.PRINTOUT_DESCRIPTION '	
	Set @Query += ''')'	
	Exec(@Query)
Go

Print 'ETL.pLoadOrderItemsFromRM created'
Go

