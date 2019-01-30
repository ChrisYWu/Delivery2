USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pLoadDeliveryForToday')
Begin
	Drop Proc ETL.pLoadDeliveryForToday
	Print '* ETL.pLoadDeliveryForToday'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*
Truncate Table ETL.DataLoadingLog 
Delete Mesh.PlannedStop
Delete Mesh.DeliveryRoute

exec ETL.pLoadDeliveryForToday

Update ETL.DataLoadingLog
Set LocalMergeDate = null
Where LogID > 11334

Go

Update ETL.DataLoadingLog


Delete From ETL.DataLoadingLog
Where LogID in (11315, 11316)

Select DeliveryDateUTC, Count(*)
From Mesh.DeliveryRoute
Group By DeliveryDateUTC

Select * 
From Mesh.PlannedStop
Go

Update Mesh.PlannedStop
Set MyDaySequence = SEquence + 1

*/

Create Proc ETL.pLoadDeliveryForToday
As
    Set NoCount On;
	Declare @LastLoadTime DateTime
	Declare @MLogID bigint, @SLogID bigint 
	Declare @OPENQUERY nvarchar(4000)
	Declare @RecordCount int
	Declare @LastRecordDate DateTime

	------------------------------------------------------
	------------------------------------------------------
	Truncate Table Staging.RS_STOP

	Select @LastLoadTime = Max(LatestLoadedRecordDate)
	From ETL.DataLoadingLog l
	Where SchemaName = 'Staging' And TableName = 'RS_ROUTE'
	And l.IsMerged = 1

	Set @LastLoadTime = Null

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'RS_STOP', GetDate())

	Select @SLogID = SCOPE_IDENTITY()

	---- STATUS CAN BE 'ACTIVE, BUILT, OR PUBLISHED'
	------------------------------------------------
	Set @OPENQUERY = 'Insert Into Staging.RS_STOP Select * From OpenQuery(' 
	Set @OPENQUERY += 'RN' +  ', ''';
	Set @OPENQUERY += ' SELECT   
					S.ROUTE_PKEY, S.RN_SESSION_PKEY,
					S.LOCATION_REGION_ID SALESOFFICE_ID, 
					S.STOP_IX, 
					S.SEQUENCE_NUMBER, 
					S.STOP_TYPE, S.LOCATION_ID ACCOUNT_NUMBER, 
					S.ARRIVAL, S.SERVICE_TIME, S.TRAVEL_TIME, S.DISTANCE, S.USER_MODIFIED, S.DATE_MODIFIED
					FROM TSDBA.RS_ROUTE R, TSDBA.RS_STOP S 
					WHERE R.STATUS = ''''PUBLISHED'''' '
	If (@LastLoadTime is null)
	Begin
		Set @OPENQUERY += 'AND R.START_TIME = TO_DATE('''''
		Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'
	End
	Else
	Begin
		Set @OPENQUERY += 'AND R.DATE_MODIFIED > TO_DATE('''''
		Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
	End
	Set @OPENQUERY += ' AND S.RN_SESSION_PKEY = R.RN_SESSION_PKEY      
					AND S.ROUTE_PKEY = R.PKEY '
	Set @OPENQUERY += ''')'	
	--Select @OPENQUERY
	Exec(@OPENQUERY)

	--2
	Select @RecordCount = Count(*) From Staging.RS_STOP
	Select @LastRecordDate = Max(DATE_MODIFIED) From Staging.RS_STOP

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY

	Where LogID = @SLogID

	--*******************************************
	--*******************************************
	Truncate Table Staging.RS_ROUTE

	Insert ETL.DataLoadingLog(SchemaName, TableName, StartDate)
	Values ('Staging', 'RS_ROUTE', GetDate())

	Select @MLogID = SCOPE_IDENTITY()

	---- STATUS CAN BE 'ACTIVE, BUILT, OR PUBLISHED', we take the PUBLISHED ----
	----------------------------------------------------------------------------
	Set @OPENQUERY = 'Insert Into Staging.RS_ROUTE Select *, 0 From OpenQuery(' 
	Set @OPENQUERY += 'RN' +  ', ''';
	Set @OPENQUERY += ' SELECT 
			R.PKEY, R.RN_SESSION_PKEY, R.ROUTE_ID, 
			R.DRIVER1_ID, E.FIRST_NAME DRIVER_FNAME, E.LAST_NAME DRIVER_LNAME, E.WORK_PHONE_NUMBER DRIVER_PHONE_NUM, 
			R.LOCATION_REGION_ID_ORIGIN, 
			R.STATUS, R.START_TIME, R.COMPLETE_TIME, R.DATE_MODIFIED, R.TRAVEL_TIME, R.SERVICE_TIME, R.BREAK_TIME, R.PREROUTE_TIME, R.POSTROUTE_TIME, R.USER_MODIFIED 
		FROM TSDBA.RS_ROUTE R LEFT JOIN TSDBA.TS_EMPLOYEE E ON R.DRIVER1_ID = E.ID 
		WHERE R.STATUS = ''''PUBLISHED'''' '
	If (@LastLoadTime is null)
	Begin
		Set @OPENQUERY += 'AND R.START_TIME = TO_DATE('''''
		Set @OPENQUERY += convert(varchar, Convert(Date, GetUTCDate()), 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'
	End
	Else
	Begin
		Set @OPENQUERY += 'AND R.DATE_MODIFIED > TO_DATE('''''
		Set @OPENQUERY += convert(varchar, @LastLoadTime, 120)
		Set @OPENQUERY += ''''', ''''YYYY-MM-DD HH24:MI:SS'''')'	
	End
	Set @OPENQUERY += ''')'	
	--Select @OPENQUERY
	Exec (@OPENQUERY)

	--1
	Select @RecordCount = Count(*) From Staging.RS_ROUTE
	Select @LastRecordDate = Max(DATE_MODIFIED) From Staging.RS_ROUTE

	Update ETL.DataLoadingLog 
	Set EndDate = GetDate(), NumberOfRecordsLoaded = @RecordCount, LatestLoadedRecordDate = @LastRecordDate, Query = @OPENQUERY
	Where LogID = @MLogID

	---------------------------------------
	---MERGING-----------------------------
	---------------------------------------

	-- Can't do historical data delete, the route level has transactional data
	--- Determine Pkey 
	Begin Try
	Declare @RoutePkey Table
	(
		ID int
	)

	Insert Into @RoutePkey
	Select Max(ID) ID
	From Staging.RS_Route r
	Join 
	(
		Select  
		Convert(Date, START_TIME) StartDate,
		ROUTE_ID, 
		Max(DATE_MODIFIED) LastUpdateTime
		From Staging.RS_Route
		Group By ROUTE_ID, Convert(Date, START_TIME)
	) s on Convert(Date, r.START_TIME) = StartDate and r.Route_ID = s.Route_ID and s.LastUpdateTime = r.DATE_MODIFIED
	Group By r.ROUTE_ID, Convert(Date, r.START_TIME)

	Update r
	Set Selected = 1
	From @RoutePkey rp
	Join Staging.RS_Route r on rp.ID = r.ID

	--- Delete the route stops is not started and has updates coming in
	Delete ps
	From Mesh.PlannedStop ps 
	Join Mesh.DeliveryRoute a on ps.DeliveryRouteID = a.DeliveryRouteID
	Where a.DeliveryDateUTC >= Convert(Date, GetUTCDate())
	And (IsStarted = 0 And LastManifestFetched is null)

	--- Delete the route is not started and has updates coming in
	Delete dr 
	From Mesh.DeliveryRoute dr
	Where DeliveryDateUTC >= Convert(Date, GetUTCDate())
	And (IsStarted = 0 And LastManifestFetched is null)

	Insert Into Mesh.DeliveryRoute
			(PKEY
			,DeliveryDateUTC
			,RouteID
			,PlannedStartTime
			,SAPBranchID
			,FirstName
			,LastName
			,PhoneNumber
			,PlannedCompleteTime
			,PlannedTravelTime
			,PlannedServiceTime
			,PlannedBreakTime
			,PlannedPreRouteTime
			,PlannedPostRouteTime
			,LastModifiedBy
			,LastModifiedUTC
			,LocalSyncTime)
	Select R.PKEY, 
		Convert(Date, START_TIME),
		Replace(R.ROUTE_ID, '.', ''), 
		START_TIME, 
		Convert(int, Substring(convert(varchar, LOCATION_REGION_ID_ORIGIN), 1, 4)), 
		dbo.udf_TitleCase(DRIVER_FNAME), 
		dbo.udf_TitleCase(DRIVER_LNAME), 
		DRIVER_PHONE_NUM, 
		COMPLETE_TIME, 
		Convert(int, TRAVEL_TIME), 
		convert(int, SERVICE_TIME), 
		Convert(int, BREAK_TIME), 
		convert(int, PREROUTE_TIME), 
		POSTROUTE_TIME, 
		USER_MODIFIED, 
		DATE_MODIFIED,
		GetDate()
	From Staging.RS_Route R
	Left Join Mesh.DeliveryRoute dr on dr.DeliveryDateUTC = Convert(Date, r.START_TIME) and convert(varchar(20), dr.RouteID) = convert(varchar(20), r.Route_ID)
	Where 
	Selected = 1
	And (Isnull(IsStarted, 0) = 0 and LastManifestFetched is null)
	And IsNumeric(Replace(R.ROUTE_ID, '.', '')) = 1

	------------------------------------------
	Insert Into Mesh.PlannedStop(
		DeliveryRouteID, 
		Pkey, 
		DeliveryDateUTC, 
		RouteID, 
		Sequence, 
		StopType, 
		SAPAccountNumber, 
		PlannedArrival, 
		TravelToTime, 
		ServiceTime, 
		LastModifiedBy, 
		LastModifiedUTC, 
		LocalSyncTime
	)
	Select 
	dr.DeliveryRouteID, 
	dr.Pkey,
	dr.DeliveryDateUTC,
	dr.RouteID, 
	s.STOP_IX, 
	s.STOP_TYPE, 
	Case When s.STOP_TYPE = 'STP' Then s.ACCOUNT_NUMBER Else NULL End, 
	s.ARRIVAL, 
	s.TRAVEL_TIME, 
	s.SERVICE_TIME, 
	s.USER_MODIFIED, 
	s.DATE_MODIFIED, 
	GetDate()
	From Staging.RS_Route r
	Join Staging.RS_Stop s on r.Pkey = s.Route_PKey
	Join Mesh.DeliveryRoute dr on dr.DeliveryDateUTC = Convert(Date, r.START_TIME) and convert(varchar(20), dr.RouteID) = convert(varchar(20), r.Route_ID)
	Where Selected = 1
	And (Isnull(IsStarted, 0) = 0 and LastManifestFetched is null)

	Update Mesh.PlannedStop
	Set SAPAccountNumber = null
	Where StopType <> 'STP'
	And SAPAccountNumber is not null

	----------------------------------------
	
	exec ETL.pFillDeliveryQuantity
	End Try
	Begin Catch
		Declare @ErrorMessage varchar(200)
		Select @ErrorMessage = Error_Message()

		Update ETL.DataLoadingLog 
		Set ErrorMessage = @ErrorMessage
		Where LogID in (@SLogID, @MLogID)	
	End Catch

	Update ETL.DataLoadingLog 
	Set LocalMergeDate = GetDate()
	Where LogID in (@SLogID, @MLogID)

Go

Print 'ETL.pLoadDeliveryForToday created'
Go

--Select *
--From mesh.DeliveryRoute
--Where RouteID = 108000536 
--And DeliveryDAteUTC
