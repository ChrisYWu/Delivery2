USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pLoadOrderPeriodically')
Begin
	Drop Proc ETL.pLoadOrderPeriodically
	Print '* ETL.pLoadOrderPeriodically'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec ETL.pLoadOrderPeriodically

*/


Create Proc ETL.pLoadOrderPeriodically
As
    Set NoCount On;
	Declare @LastLoadTime DateTime
	Declare @MLogID bigint, @SLogID bigint 
	Declare @OPENQUERY nvarchar(4000)
	Declare @RecordCount int
	Declare @LastRecordDate DateTime
	Declare @ErrorMessage nvarchar(max), @ErrorSeverity int, @ErrorState int;

	------------------------------------------------------
	------------------------------------------------------
	Truncate Table Staging.ORDER_DETAIL

	Select @LastLoadTime = Max(LatestLoadedRecordDate)
	From ETL.DataLoadingLog l
	Where SchemaName = 'Staging' And TableName = 'ORDER_MASTER'
	And l.IsMerged = 1

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'ORDER_DETAIL', GetDate())

	Select @SLogID = SCOPE_IDENTITY()

	----=-------------------------------------------
	------------------------------------------------
	Begin Try
		Set @OPENQUERY = 'Insert Into Staging.ORDER_DETAIL Select * From OpenQuery(' 
		Set @OPENQUERY += 'RM' +  ', ''';
		Set @OPENQUERY += 'SELECT OM.ORDER_NUMBER, ITEM_NUMBER, SUM(CASEQTY) CASEQTY, MAX(NVL(OD.UPDATE_TIME, OD.INSERT_TIME)) UPDATE_TIME '
		Set @OPENQUERY += ' FROM ACEUSER.ORDER_MASTER OM, ACEUSER.ORDER_DETAIL OD '
		Set @OPENQUERY += ' WHERE OM.ORDERSTATUS IN (2,3,4) '
		Set @OPENQUERY += ' AND OM.ORDER_NUMBER = OD.ORDER_NUMBER '
		Set @OPENQUERY += ' AND OD.TYPE in ( ''''O'''', ''''F'''' ) '
		If (@LastLoadTime is null)
		Begin
			Set @OPENQUERY += 'AND DELIVERYDATE >= TO_DATE('''''
			Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD '''')'
		End
		Else
		Begin
			Set @OPENQUERY += 'AND OM.UPDATE_TIME > TO_DATE('''''
			Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
		End
		Set @OPENQUERY += ' GROUP BY OM.ORDER_NUMBER, ITEM_NUMBER '	
		Set @OPENQUERY += ''')'	
		Select @OPENQUERY
		Exec (@OPENQUERY)
	End Try
	Begin Catch
		Update ETL.DataLoadingLog 
		Set ErrorMessage = ERROR_MESSAGE(), ErrorStep = 'Load DETAILS from RM'
		Where LogID = @SLogID

		Select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		RaisError (@ErrorMessage, @ErrorSeverity, @ErrorState);
	End Catch


	--2
	Select @RecordCount = Count(*) From Staging.ORDER_DETAIL
	Select @LastRecordDate = Max(UPDATE_TIME) From Staging.ORDER_DETAIL

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY
	Where LogID = @SLogID



	--*******************************************
	--*******************************************
	-- Reuse the @LastLoadTime from the order master table
	Truncate Table Staging.ORDER_MASTER

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'ORDER_MASTER', GetDate())

	Select @MLogID = SCOPE_IDENTITY()

	---------------------------------------------
	Begin Try
		Set @OPENQUERY = 'Insert Into Staging.ORDER_MASTER Select * From OpenQuery(' 
		Set @OPENQUERY += 'RM' +  ', ''';
		Set @OPENQUERY += 'SELECT ORDER_NUMBER, CUSTOMER_NUMBER, LOCATION_ID, DELIVERYROUTE, DELIVERYDATE, ORDERSTATUS, ORDERAMOUNT, DNS, UPDATE_TIME '
		Set @OPENQUERY += ' FROM ACEUSER.ORDER_MASTER '
		Set @OPENQUERY += ' WHERE ORDERSTATUS IN (2,3,4) '
		If (@LastLoadTime is null)
		Begin
			Set @OPENQUERY += 'AND DELIVERYDATE >= TO_DATE('''''
			Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD '''')'
		End
		Else
		Begin
			Set @OPENQUERY += 'AND UPDATE_TIME > TO_DATE('''''
			Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
			Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
		End
		Set @OPENQUERY += ''')'	
		Select @OPENQUERY
		Exec (@OPENQUERY)
	End Try
	Begin Catch
		Update ETL.DataLoadingLog 
		Set ErrorMessage = ERROR_MESSAGE(), ErrorStep = 'Load ORDER_MASTER from RM'
		Where LogID in (@MLogID)

		Select @ErrorMessage = ERROR_MESSAGE() + ' Line ' + cast(ERROR_LINE() as nvarchar(5)), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();
		RaisError (@ErrorMessage, @ErrorSeverity, @ErrorState);
	End Catch
	--1

	Select @RecordCount = Count(*) From Staging.ORDER_MASTER
	Select @LastRecordDate = Max(UPDATE_TIME) From Staging.ORDER_MASTER

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY
	Where LogID = @MLogID

	---------------------------------------
	---MERGING-----------------------------
	---------------------------------------
	-- Historical data delete
	Delete
	From Mesh.CustomerOrder
	Where DateDiff(day, DeliveryDateUTC, GetUTCDate()) > 3


	--- Delete order items that has been updated
	Delete ds
	From Mesh.OrderItem ds
	Join Mesh.CustomerOrder dr on ds.RMOrderID = dr.RMOrderID
	Join Staging.ORDER_MASTER R on dr.RMOrderID = R.ORDER_NUMBER

	--- Delete the order master that has been updated
	Delete dr
	From Mesh.CustomerOrder dr
	Join Staging.ORDER_MASTER R on dr.RMOrderID = R.ORDER_NUMBER

	INSERT INTO Mesh.CustomerOrder
			   (RMOrderID
			   ,DeliveryDateUTC
			   ,SAPBranchID
			   ,RMOrderStatus
			   ,RouteID
			   ,DNS
			   ,SAPAccountNumber 
			   ,RMLastModified
			   ,LocalSyncTime)
	Select ORDER_NUMBER, DELIVERYDATE, substring(Location_ID, 1, 4), ORDERSTATUS, DELIVERYROUTE, DNS, CUSTOMER_NUMBER, UPDATE_TIME 
		,GetDate()
	From Staging.ORDER_MASTER R

	------------------------------------------
	Insert Into Mesh.OrderItem
			   (RMOrderID
			   ,ItemNumber
			   ,Quantity
			   ,RMLastModified
			   ,RMLastModifiedBy
			   ,LocalSyncTime)
	Select ORDER_NUMBER, ITEM_NUMBER, CASEQTY, UPDATE_TIME, 'System', GetDate()
	From Staging.ORDER_DETAIL
	Where ORDER_NUMBER In (Select ORDER_NUMBER From Staging.ORDER_MASTER)
	And CASEQTY > 0

	----------------------------------------
	exec ETL.pFillDeliveryQuantity

	Update ETL.DataLoadingLog 
	Set LocalMergeDate = GetDate()
	Where LogID in (@SLogID, @MLogID)


Go

Print 'ETL.pLoadOrderPeriodically created'
Go

