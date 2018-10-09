USE [Merch]
GO
/****** Object:  StoredProcedure [Planning].[pGetPreDispatch]    Script Date: 5/24/2018 12:25:41 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

exec Planning.pGetPreDispatch @MerchGroupID = 257, @DispatchDate = '2017-08-01', @GSN = 'System', @Reset = 1
exec Planning.pGetPreDispatch @MerchGroupID = 28, @DispatchDate = '2018-06-13', @GSN = 'System'

*/

ALTER Proc [Planning].[pGetPreDispatch]
(
	@MerchGroupID int,
	@DispatchDate date = null,
	@GSN varchar(50),
	@TimeZoneOffsetToUTC int = 0,
	@Reset bit = 0,
	@Debug bit = 0
)
As
Begin
	If (@Debug = 1)
	Begin
		DECLARE @StartTime DateTime2(7)
		Set @StartTime = SYSDATETIME()
		Select '---- Starting ----' Debug, @StartTime StartTime 
	End

	If @DispatchDate Is Null
	Begin
		Set @DispatchDate = Convert(Date, GetDate())
	End

	Declare @NumberOfChangeSet int
	Select @NumberOfChangeSet = Count(*)
	From (
		Select LastModified
		From Planning.PreDispatch d
		Where MerchGroupID = @MerchGroupID
		And DispatchDate = @DispatchDate
		Group By LastModified
	) temp

	Declare @NumberOfDeploySet int
	Select @NumberOfDeploySet = Count(*)
	From (
		Select ReleaseTime
		From Planning.DispatchBatch d
		Where MerchGroupID = @MerchGroupID
		And DispatchDate = @DispatchDate
	) temp

	Declare @ModifiedTimeStamp DateTime2(7)

	-- Reset Requested
	If (@Reset = 1)
	Begin
		Delete 
		From Planning.PreDispatch
		Where MerchGroupID = @MerchGroupID 
		And DispatchDate = @DispatchDate
		And RouteID <> -1

		Set @ModifiedTimeStamp = SYSUTCDATETIME()

		Insert Into Planning.PreDispatch(DispatchDate, MerchGroupID, SAPAccountNumber, Sequence, GSN, RouteID, LastModified, LastModifiedBy)
		Select @DispatchDate DispatchDate, rsw.MerchGroupID, rsw.SAPAccountNumber, rsw.Sequence, GSN, rsw.RouteID, @ModifiedTimeStamp, @GSN
		From Planning.RouteMerchandiser rm 
		Join Planning.RouteStoreWeekday rsw on rm.RouteID = rsw.RouteID and rm.DayOfWeek = rsw.DayOfWeek
		Where DatePart(dw, @DispatchDate) = rm.DayOfWeek
		And @MerchGroupID = MerchGroupID
		
		Update d
		Set d.SameStoreSequence = t.SameStoreSequence
		From Planning.PreDispatch d
		Join (
			Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
			From Planning.PreDispatch
			Where MerchGroupID = @MerchGroupID And DispatchDate = @DispatchDate
		) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID
	End

	-- @NumberOfChangeSet = 1. In Preview and never released, keep updating from planning for preview untill change set increases or deployset increates
	-- @NumberOfChangeSet = 0. Never loaded, keep updating from planning for preview untill change set increases or deployset increates
	If ((@NumberOfChangeSet < 2) And (@NumberOfDeploySet = 0))
	Begin
		Delete 
		From Planning.PreDispatch
		Where MerchGroupID = @MerchGroupID 
		And DispatchDate = @DispatchDate

		Set @ModifiedTimeStamp = SYSUTCDATETIME()

		Insert Into Planning.PreDispatch(DispatchDate, MerchGroupID, SAPAccountNumber, Sequence, GSN, RouteID, LastModified, LastModifiedBy)
		Select @DispatchDate DispatchDate, rsw.MerchGroupID, rsw.SAPAccountNumber, rsw.Sequence, GSN, rsw.RouteID, @ModifiedTimeStamp, @GSN
		From Planning.RouteMerchandiser rm 
		Join Planning.RouteStoreWeekday rsw on rm.RouteID = rsw.RouteID and rm.DayOfWeek = rsw.DayOfWeek
		Where DatePart(dw, @DispatchDate) = rm.DayOfWeek
		And @MerchGroupID = MerchGroupID
		Union 
		Select @DispatchDate DispatchDate, @MerchGroupID, '-1', -1, 'FirstLoadPlaceHolder', -1, @ModifiedTimeStamp, @GSN
		
		Update d
		Set d.SameStoreSequence = t.SameStoreSequence
		From Planning.PreDispatch d
		Join (
			Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
			From Planning.PreDispatch
			Where MerchGroupID = @MerchGroupID And DispatchDate = @DispatchDate
		) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID

	End

	--Just Reset and never been released ===  updated and reset later while never released, 
	--Sync the time stamp and have it follow the plan if no future modification is made
	If (@Reset= 1 And @NumberOfDeploySet = 0 And @ModifiedTimeStamp is not null)
	Begin
		Update Planning.PreDispatch
		Set LastModified = @ModifiedTimeStamp
		Where MerchGroupID = @MerchGroupID
		And DispatchDate = @DispatchDate
	End

	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
	

	Declare @StoreDelivery Table
	(
		DispatchDate Date,
		SAPAccountNumber int,
		IsMesh bit,
		PlannedArrival DateTime,
		EstimatedArrival DateTime,
		ActualArrival DateTime,
		ActualDeparture DateTime,
		DNS bit
	)

	Declare @Value varchar(max)

	Select @Value = Value
	From Setup.Config
	Where [Key] = 'MeshEnabledBranches'

	If Exists (Select * From Setup.MerchGroup 
				Where MerchGroupID = @MerchGroupID 
				And SAPBranchID in (Select Value From dbo.udfSplit(@Value, ','))
			)
	Begin
		Insert Into @StoreDelivery
		Select pd.DispatchDate, pd.SAPAccountNumber, 1, PlannedArrival, Null As EstimatedArrivalTime, Null As ArrivalTime, Null ActualDeparture, 0
		From Planning.PreDispatch pd
		Join Mesh.PlannedStop ds on pd.DispatchDate = ds.DeliveryDateUTC and pd.SAPAccountNumber = ds.SAPAccountNumber
		Where DispatchDate = @DispatchDate
		And @MerchGroupID = MerchGroupID
		And IsNumeric(ds.SAPAccountNumber) = 1

		Update s
		Set EstimatedArrival = EstimatedArrivalTime, ActualArrival = ArrivalTime, ActualDeparture = DepartureTime, s.DNS = ds.DNS
		From @StoreDelivery s
		Join Mesh.DeliveryStop ds on s.DispatchDate = ds.DeliveryDateUTC and s.SAPAccountNumber = ds.SAPAccountNumber
		Where IsNumeric(ds.SAPAccountNumber) = 1

	End
	Else
	Begin
		Insert Into @StoreDelivery
		Select pd.DispatchDate, pd.SAPAccountNumber, 0, PlannedArrival, Null EstimatedArrival, Null ActualArrival, ActualArrival ActualDeparture, 0
		From Planning.PreDispatch pd
		Join Operation.StoreDelivery ds on pd.DispatchDate = ds.DeliveryDate and pd.SAPAccountNumber = ds.SAPAccountNumber
		Where DispatchDate = @DispatchDate
		And @MerchGroupID = MerchGroupID
	End

	If (@Debug = 1)
	Begin
		Select '---- Dumping @StoreDelivery for MeshEnabledBranches----' Debug, DATEDIFF(ms, @StartTime, SYSDATETIME()) ExecutionTimeInMilliSeconds		

		Select * From @StoreDelivery
	End
	--^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^--
			
	Select * into #DipatchTable from 
	(
	Select pd.DispatchDate, pd.MerchGroupID, pd.SAPAccountNumber, a.AccountName + ' (' + convert(varchar, a.SAPAccountNumber) + ')' AccountName, pd.RouteID, r.RouteName, pd.Sequence, pd.GSN, IsNull(p.FirstName, '+ Add') FirstName, IsNull(p.LastName, 'Merchandiser') LastName, pd.LastModified, pd.LastModifiedBy, IsNull(ab.AbsoluteURL, '') AbsoluteURL
	, (CASE WHEN d.StoreVisitStatusID = 3 THEN 'GREEN' WHEN d.StoreVisitStatusID = 2 THEN 'GRAY' ELSE '' END) as CheckInGSN
	, (CASE 
			WHEN ISNULL(sd.DNS, 0) = 1 
				THEN  'DELIVERY  ' +  'CANCELLED'
			WHEN ISNULL(sd.ActualDeparture, '') != '' 
				THEN  Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.ActualDeparture),100),7)), '') + ' ' +  ' DELIVERED'
			WHEN ISNULL(sd.ActualArrival, '') != '' 
				THEN  Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.ActualArrival),100),7)), '') + ' ' +  ' ARRIVED'
			WHEN ISNULL(sd.EstimatedArrival, '') != '' 
				THEN  Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.EstimatedArrival),100),7)), '') + ' ' +  ' ETA'
			WHEN ISNULL(sd.PlannedArrival, '') != '' 
				THEN Isnull(LTRIM(RIGHT(CONVERT(CHAR(19),DateAdd(hour, -1 * @TimeZoneOffsetToUTC, sd.PlannedArrival),100),7)), '') + ' ' +  ' SCHEDULE'
		   ELSE 'NO  DELIVERY'
	  END) ActualArrival
	   
	From Planning.PreDispatch pd
	Join SAP.Account a on pd.SAPAccountNumber = a.SAPAccountNumber
	Join Planning.Route r on pd.RouteID = r.RouteID
	Left Join Setup.Person p on pd.GSN = p.GSN
	Left Join Setup.ProfileImage pimage on pimage.GSN = p.GSN
	LEFT JOIN Operation.AzureBlobStorage ab on ab.BlobID = pimage.ImageBlobID
	LEFT JOIN Planning.Dispatch d on d.RouteID = pd.RouteID and d.DispatchDate = pd.DispatchDate and d.GSN = pd.GSN and d.SAPAccountNumber = pd.SAPAccountNumber 
	and d.Sequence = pd.Sequence and d.InValidatedBatchID is NULL
	LEFT JOIN @StoreDelivery sd on sd.SAPAccountNumber = pd.SAPAccountNumber and sd.DispatchDate = pd.DispatchDate
	Where @DispatchDate = pd.DispatchDate
	And pd.MerchGroupID = @MerchGroupID
	
	Union
	Select @DispatchDate, @MerchGroupID, '' SAPAccountNumber, '' AccountName, RouteID, RouteName, -1 Sequence, '' GSN, '+ Add' FirstName, 'Merchandiser' LastName, GetDate() LastModified, null LastModifiedBy,  '' AbsoluteURL
	 ,'' CheckInGSN, '' ActualArrival
	From Planning.Route
	Where MerchGroupID = @MerchGroupID
	And RouteID Not In (
		Select Distinct RouteID
		From Planning.PreDispatch
		Where DispatchDate = @DispatchDate --@DispatchDate
		And MerchGroupID = @MerchGroupID--@MerchGroupID
	)
	)T
	Order by RouteID, Sequence

	---Get the count of promotions that needs to be displayed by sapaccountnumber
	select b.SAPAccountNumber,Count(distinct PromotionID) as DisplayTaskCount into #DisplayCount 
	from [Operation].[DisplayBuild] b
	INNER JOIN #DipatchTable d ON b.SAPAccountNumber = d.SAPAccountNumber
	where @DispatchDate>=ProposedStartDate and  @DispatchDate<=ProposedEndDate and BuildDate is null	
	and b.RequiresDisplay = 1 and b.PromotionExecutionStatusID = 2
	group by b.SAPAccountNumber

	Select t.*,isNULL(d.DisplayTaskCount,0) as DisplayTaskCount 
	from #DipatchTable t
	Left JOIN #DisplayCount d ON t.SAPAccountNumber = d.SAPAccountNumber
	Order by t.RouteID, t.Sequence
	
	-- Last Scheduled Date
	SELECT isnull(Count([ReleaseTime]),0) as ScheduleDateCount	
	FROM [Planning].[DispatchBatch] d
	Inner Join [Setup].[Person] p On p.GSN = d.ReleaedBy
	Where merchgroupid = @MerchGroupID and dispatchdate=@DispatchDate
End
Go

exec Planning.pGetPreDispatch @MerchGroupID = 28, @DispatchDate = '2018-06-27', @GSN = 'System', @Debug = 1
