USE Merch
GO
/****** Object:  StoredProcedure [Export].[pGetStoreServiceReport]    Script Date: 9/5/2018 2:33:21 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

If Exists (
	Select *
	From sys.sql_modules m
	Join sys.objects o on m.object_id = o.object_id
	Where name = 'udfDistanceInMiles')
Begin
	Drop Function dbo.udfDistanceInMiles
	Print '* dbo.udfDistanceInMiles'
End
Go

/*
Select Top 1 CheckInLatitude, CheckInLongitude, CheckoutLatitude, CheckoutLongitude, dbo.udfDistanceInMiles(Null,CheckinLongitude,Checkoutlatitude, CheckoutLongitude), *
From Operation.MerchStopCheckIn i
Join Operation.MerchStopCheckOut o on i.MerchStopID = o.MerchStopID
Where CheckInLatitude <> 0 
Order By i.MerchStopID Desc
Go

*/
Create Function dbo.udfDistanceInMiles
(
	@LatAnchor decimal(10,6) = null, 
	@LongAnchor decimal(10,6) = null, 
	@LatTarget decimal(10,6) = null, 
	@LongTarget decimal(10,6) = null
)
Returns Decimal(10,1)
As
Begin
	Declare @Result Decimal(10,1) = null
	
	If ((@LatAnchor is not null) And (@LongAnchor is not null) And (@LatTarget is not null) And (@LongTarget is not null))
	Begin
		Declare @Anchor geography = geography::Point(@LatAnchor, @LongAnchor, 4326);
		Declare @Target geography = geography::Point(@LatTarget, @LongTarget, 4326);

		Select @Result = @Anchor.STDistance(@Target)*0.000621371 -- Meter converted to miles
	End

	Return @Result

End
Go

Print 'Creating user function dbo.udfDistanceInMiles at ' + convert(varchar(200), GetDate())
Go

-------------------------------------------------------------------------------------------------
If Not Exists (Select t.name 
From sys.columns s
Join sys.tables t on s.object_id = t.object_id
Where s.name = 'CheckInDistanceInMiles'
And t.name = 'MerchStopcheckIn')
Begin
	Alter Table Operation.MerchStopcheckIn
	Add CheckInDistanceInMiles Decimal(11,1)

	Print 'CheckInDistanceInMiles column added to table Operation.MerchStopcheckIn at ' + convert(varchar(200), GetDate())
End
Go

Update chkIn
Set CheckInDistanceInMiles = dbo.udfDistanceInMiles(acc.Latitude, acc.Longitude, chkIn.CheckInLatitude, chkIn.CheckInLongitude)
From Operation.MerchStopcheckIn chkIn
Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
Go

Print 'Operation.MerchStopcheckIn updated at ' + convert(varchar(200), GetDate())
Go

If Not Exists (Select t.name 
From sys.columns s
Join sys.tables t on s.object_id = t.object_id
Where s.name = 'CheckOutDistanceInMiles'
And t.name = 'MerchStopcheckOut')
Begin
	Alter Table Operation.MerchStopcheckOut
	Add CheckOutDistanceInMiles Decimal(11,1)

	Print 'CheckOutDistanceInMiles column added to table Operation.MerchStopcheckOut at ' + convert(varchar(200), GetDate())
End
Go

Update o
Set CheckOutDistanceInMiles = dbo.udfDistanceInMiles(acc.Latitude, acc.Longitude, o.CheckOutLatitude, o.CheckOutLongitude)
From Operation.MerchStopcheckIn chkIn
Join Operation.merchStopcheckOut o on chkIn.MerchStopID = o.MerchStopID
Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
Go

Print 'Operation.MerchStopcheckOut updated at ' + convert(varchar(200), GetDate())
Go

-------------------------------------------------------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

EXEC Export.pGetStoreServiceReport '5,7', '2017-12-12', '2017-12-12'
EXEC Export.pGetStoreServiceReport '184', '2017-12-2', '2017-12-22'

*/

ALTER Proc [Export].[pGetStoreServiceReport]
(
	@MerchGroupIDs VARCHAR(4000),
	@FromDate Date,
	@ToDate Date
)
AS

BEGIN

	Select  branch.BranchName as Branch,
		ltrim(p.FirstName) + ' ' + ltrim(p.LastName) as Merchandiser,
		convert(varchar, chkOut.ClientCheckOutTime, 101) as 'Date',
		chain.LocalChainName as 'Chain',
		acc.AccountName as 'StoreName', 
		convert(nvarchar, CAST(chkIn.ClientCheckInTime as time), 100)  + ' ' + chkIn.ClientCheckInTimeZone as 'StartTime',	
		convert(nvarchar, CAST(chkOut.ClientCheckOutTime as time), 100)  + ' ' + chkOut.ClientCheckOutTimeZone as 'EndTime',
		chkIn.ClientCheckInTime,
		chkOut.ClientCheckOutTime,	 
		convert(varchar(10),DateDiff(minute, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime) ) as 'TimeinStoreMins',
		convert(varchar(5),DateDiff(s, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime)/3600)+' hrs '+convert(varchar(5),DateDiff(s, chkIn.ClientCheckInTime, chkOut.ClientCheckOutTime)%3600/60) + ' mins' as 'TimeinStoreHours',
		REPLACE(ltrim(sig.ManagerName), ',',' ') as 'ManagerName', 		
		CAST(sig.ImageBlobID as VARCHAR(50)) as 'ManagerSignature',		
		chkOut.CasesHandeled as 'CasesWorked', 
		chkOut.CasesInBackroom as 'CasesInBackstock',		
		STUFF((
				Select ';' + CAST(pic.PictureBlobID as VARCHAR(50)) from Operation.MerchStorePicture pic 
				where pic.DispatchDate = chkIn.DispatchDate and pic.GSN = chkIn.GSN and pic.SAPAccountNumber = chkIn.SAPAccountNumber and pic.DispatchDate = chkIn.DispatchDate
			FOR XML PATH('')
					,TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as 'StorePics',
		

		STUFF((
				Select '; ' + pic.Caption from Operation.MerchStorePicture pic 
				where pic.DispatchDate = chkIn.DispatchDate and pic.GSN = chkIn.GSN and pic.SAPAccountNumber = chkIn.SAPAccountNumber and pic.DispatchDate = chkIn.DispatchDate
			FOR XML PATH('')
					,TYPE
				).value('.', 'NVARCHAR(MAX)'), 1, 1, '') as 'PicsLocation',
		Replace(Replace(Replace(chkOut.Comments, ',', ';'), Char(10), ''), Char(13), '') Comments,
		chkIn.CheckInDistanceInMiles CKINDistance,
		chkOut.CheckOutDistanceInMiles CKOUTDistance,
		'"' + convert(varchar(40),acc.Latitude)  + ',' + convert(varchar(40),acc.Longitude) + '"' as 'StoreLocation',
		'"' + convert(varchar(40),chkIn.CheckInLatitude)  + ',' + convert(varchar(40),chkIn.CheckInLongitude) + '"' as 'CKINLocation',
		'"' + convert(varchar(40),chkOut.CheckOutLatitude)  + ',' + convert(varchar(40),chkOut.CheckOutLongitude) + '"' as 'CKOUTLocation',
		acc.Address, acc.City,acc.PostalCode, acc.State
	from Operation.MerchStopCheckIn chkIn 
	left Join Operation.MerchStopCheckOut chkOut  on chkIn.MerchStopID = chkOut.MerchStopID
	left Join SAP.Account acc on chkIn.SAPAccountNumber = acc.SAPAccountNumber
	left join SAP.LocalChain chain on acc.LocalChainID = chain.LocalChainID
	left join Operation.MerchStoreSignature sig on chkIn.GSN = sig.GSN  and sig.SAPAccountNumber = chkIn.SAPAccountNumber and sig.DispatchDate = chkIn.DispatchDate
	left join Setup.MerchGroup grp on chkIn.MerchGroupID = grp.MerchGroupID
	inner join SAP.Branch branch on branch.SAPBranchID = grp.SAPBranchID
	left join Setup.Person p on p.GSN = chkIn.GSN
	Where chkIn.MerchGroupID in (Select value  From Setup.UDFSplit(@MerchGroupIDs, ','))
		AND chkIn.DispatchDate between @FromDate and @ToDate
		
END
Go

Print 'Export.pGetStoreServiceReport updated at ' + convert(varchar(200), GetDate())
Go

------------------------------------------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

EXEC [Operation].[pInsertMerchStopCheckIn]
	 @DispatchDate = '2016-07-06'
	,@GSN= 'ADEAX015'
	,@MerchGroupID=201
	,@ClientSequence=1	
	,@SameStoreSequence=1
	,@RouteID=10136
	,@SAPAccountNumber=11228986
	,@IsOffRouteStop=0
	,@ClientCheckInTime='2016-07-05'
	,@ClientCheckInTimeZone='CDT'	
	,@CheckInLatitude=31.617078
	,@CheckInLongitude=-97.052886
	,@DriveTimeInMinutes=40
	,@StandardMileage=0.0
	,@UserMileage=0.00
	
*/

ALTER PROCEDURE [Operation].[pInsertMerchStopCheckIn]
(
	 --- Keys ---
	 @DispatchDate Date,
	 @GSN VARCHAR(50),
	 @MerchGroupID int,
	 @SameStoreSequence int,
	 @ClientSequence int,

	 --- Properties ---
	 @RouteID int = null,
	 @SAPAccountNumber bigint,
	 @IsOffRouteStop bit,
	 @ClientCheckInTime DateTime,
	 @ClientCheckInTimeZone varchar(10),	
	 @CheckInLatitude decimal(10, 6),
	 @CheckInLongitude decimal(10,6),
	 @DriveTimeInMinutes int,
	 @StandardMileage decimal(7,2),
	 @UserMileage decimal(7,2) = 0.00
)
AS 

BEGIN

	Set NoCount On;
	Set @GSN = Upper(@GSN)
	
	IF (@UserMileage = 0.00)
		Set @UserMileage = @StandardMileage

	Declare @MerchStopID Int
	Declare @StoreLat Decimal(10,6)
	Declare @StoreLong Decimal(10,6)

	IF EXISTS
	(
		SELECT * FROM Operation.MerchStopCheckIn 
		WHERE DispatchDate = @DispatchDate 
		AND GSN = @GSN 
		AND SameStoreSequence = @SameStoreSequence 
		And SAPAccountNumber = @SAPAccountNumber
		AND MerchGroupID = @MerchGroupID
	)
	BEGIN 
		Select @MerchStopID = MerchStopID, @StoreLat = a.Latitude, @StoreLong = a.Longitude
		From Operation.MerchStopCheckIn inn
		Left Join SAP.Account a on inn.SAPAccountNumber = a.SAPAccountNumber
		WHERE DispatchDate = @DispatchDate 
		AND GSN = @GSN 
		AND SameStoreSequence = @SameStoreSequence 
		And inn.SAPAccountNumber = @SAPAccountNumber
		AND MerchGroupID = @MerchGroupID

		UPDATE Operation.MerchStopCheckIn
		SET RouteID = @RouteID,
			SAPAccountNumber = @SAPAccountNumber,
			IsOffRouteStop = @IsOffRouteStop, 
			ClientCheckInTime = @ClientCheckInTime,
			ClientCheckInTimeZone = @ClientCheckInTimeZone,
			CheckInLatitude = @CheckInLatitude,
			CheckInLongitude = @CheckInLongitude,
			DriveTimeInMinutes = @DriveTimeInMinutes,
			StandardMileage = @StandardMileage,
			UserMileage = @UserMileage,
			ClientSequence = @ClientSequence,
			CheckInDistanceInMiles = dbo.udfDistanceInMiles(@StoreLat, @StoreLong, @CheckInLatitude, @CheckInLongitude),
			UTCUpdateTime = SysUTCDateTime()  
		WHERE @MerchStopID = MerchStopID
	END
	ELSE
	BEGIN 
		Select @StoreLat = Latitude, @StoreLong = Longitude
		From SAP.Account
		Where SAPAccountNumber = @SAPAccountNumber

		INSERT INTO Operation.MerchStopCheckIn(DispatchDate, GSN, MerchGroupID, ClientSequence, SameStoreSequence, RouteID, SAPAccountNumber, IsOffRouteStop, 
		ClientCheckInTime, 
		ClientCheckInTimeZone,
		CheckInLatitude, CheckInLongitude, DriveTimeInMinutes, StandardMileage, UserMileage, UTCInsertTime, UTCUpdateTime, CheckInDistanceInMiles)
		VALUES (
		@DispatchDate, 
		Upper(@GSN), @MerchGroupID, @ClientSequence, @SameStoreSequence, @RouteID, @SAPAccountNumber, @IsOffRouteStop, 
		@ClientCheckInTime, 
		@ClientCheckInTimeZone,
		@CheckInLatitude, 
		@CheckInLongitude, @DriveTimeInMinutes, @StandardMileage, @UserMileage, SysUTCDateTime(), SysUTCDateTime(), dbo.udfDistanceInMiles(@StoreLat, @StoreLong, @CheckInLatitude, @CheckInLongitude))
		
		Select @MerchStopID = Scope_Identity()
	END

	----- Reset the Sequence ----
	Update i
	Set i.ReportInSequence = temp.Seq
	From 
	Operation.MerchStopCheckIn i Join
	(
		Select DispatchDate, GSN, MerchGroupID, MerchStopID, Row_Number() Over (Order By ClientCheckInTime) Seq
		From Operation.MerchStopCheckIn
		WHERE DispatchDate = @DispatchDate 
		AND GSN = @GSN 
		AND MerchGroupID = @MerchGroupID
	) temp on i.MerchStopID = temp.MerchStopID
	
	---Update StoreVisitStatus value because user has checkedin in store
	---Now after the updates there would be multiple, some are invalidated, but this should work
	Update Planning.Dispatch 	 
		Set StoreVisitStatusID = 2
	WHERE DispatchDate = @DispatchDate 
		AND GSN = @GSN 
		AND MerchGroupID = @MerchGroupID
		And SAPAccountNumber = @SAPAccountNumber
		--AND RouteID = @RouteID
		And InvalidatedBatchID is null
		AND SameStoreSequence = @SameStoreSequence
		And StoreVisitStatusID = 1


	---Update DNS record if found from Operation.MerchStopDNS table

	IF EXISTS
	(
		SELECT * FROM Operation.MerchStopDNS
		WHERE DispatchDate = @DispatchDate 
		AND GSN = @GSN 	
		And SAPAccountNumber = @SAPAccountNumber
		AND MerchGroupID = @MerchGroupID
		AND RouteID = @RouteID
		AND SameStoreSequence = @SameStoreSequence
	)
	BEGIN
		UPDATE Operation.MerchStopDNS
			SET Active = 0
		WHERE DispatchDate = @DispatchDate 
		AND GSN = @GSN 	
		And SAPAccountNumber = @SAPAccountNumber
		AND MerchGroupID = @MerchGroupID
		AND RouteID = @RouteID
		AND SameStoreSequence = @SameStoreSequence
	END

	---- Insert/Update data in GSN Activity log table	
	IF EXISTS(
			SELECT * FROM Operation.GSNActivityLog
			WHERE GSN = @GSN AND SAPAccountNumber = @SAPAccountNumber AND Activity = 'Check In' AND ClientTime = @ClientCheckInTime AND ClientTimeZone = @ClientCheckInTimeZone
			)
		BEGIN
			UPDATE Operation.GSNActivityLog 
				SET UTCUpdateTime = SysUTCDateTime()
				WHERE GSN = @GSN AND SAPAccountNumber = @SAPAccountNumber AND Activity = 'Check In' AND ClientTime = @ClientCheckInTime AND ClientTimeZone = @ClientCheckInTimeZone
		END
	ELSE
		BEGIN		
			INSERT INTO Operation.GSNActivityLog (OperationDate, GSN, SAPAccountNumber, Activity, ClientTime,ClientTimeZone, 
			UTCInsertTime, UTCUpdateTime)
			VALUES (@DispatchDate, @GSN, @SAPAccountNumber, 'Check In', @ClientCheckInTime, @ClientCheckInTimeZone, SysUTCDateTime(), SysUTCDateTime())			
		END
END
Go

Print 'Export.pInsertMerchStopCheckIn updated at ' + convert(varchar(200), GetDate())
Go

---------------------------------------------------------------------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
EXEC [Operation].[pInsertMerchStopCheckIn]
	 @DispatchDate = '2016-07-06'
	,@GSN= 'ADEAX015'
	,@MerchGroupID=101
	,@ClientSequence=1	
	,@RouteID=null
	,@SAPAccountNumber=11228986
	,@IsOffRouteStop=1
	,@ClientCheckInTime='2016-07-06 06:35:22 AM'
	,@ClientCheckInTimeZone='CDT'	
	,@CheckInLatitude=31.617078
	,@CheckInLongitude=-97.052886
	,@DriveTimeInMinutes= 13
	,@StandardMileage=8
	,@UserMileage=9


EXEC [Operation].[pInsertMerchStopCheckOut]
	  @DispatchDate= '2016-09-06'
	, @GSN= 'ADEAX015'
	, @ClientSequence= 1
	, @MerchGroupID = 101
	, @SAPAccountNumber= 11228986
	, @ClientCheckOutTime='2016-07-06 08:17:59 AM'
	, @ClientCheckOutTimeZone='CDT'
	, @CheckOutLatitude= 31.617078
	, @CheckOutLongitude=-97.052886
	, @CasesHandeled= 12
	, @CasesInBackroom= 30
	, @Comments='Test Data'
	, @AtAccountTimeInMinute=102

*/

ALTER PROCEDURE [Operation].[pInsertMerchStopCheckOut]
(
	 @DispatchDate Date,
	 @GSN varchar(50),
	 @ClientSequence int,
	 @SameStoreSequence int,
	 @MerchGroupID int,
	 
	 @SAPAccountNumber bigint,
	 @ClientCheckOutTime datetime,
	 @ClientCheckOutTimeZone varchar(10),
	 @CheckOutLatitude decimal(10,6),
	 @CheckOutLongitude decimal(10,6),
	 @CasesHandeled int,
	 @CasesInBackroom int,
	 @Comments varchar(1000) = '',
	 @AtAccountTimeInMinute int
)
AS
BEGIN

	DECLARE @CheckInMerchStopID INT
	DECLARE @CheckOutMerchStopID INT
	Declare @RouteID Int
	Declare @StoreLat Decimal(10,6)
	Declare @StoreLong Decimal(10,6)

	SELECT @CheckInMerchStopID = MerchStopID, @RouteID = RouteID, @StoreLat = a.Latitude, @StoreLong = a.Longitude
	FROM Operation.MerchStopCheckIn Inn
	Left Join SAP.Account a on inn.SAPAccountNumber = a.SAPAccountNumber
	WHERE DispatchDate = @DispatchDate AND GSN = @GSN AND SameStoreSequence  = @SameStoreSequence AND inn.SAPAccountNumber = @SAPAccountNumber And MerchGroupID = @MerchGroupID

	SELECT @CheckOutMerchStopID = MerchStopID FROM Operation.MerchStopCheckOut WHERE MerchStopID = @CheckInMerchStopID 

	IF ((@CheckInMerchStopID is not null) And (@CheckOutMerchStopID is null))
		BEGIN

			INSERT INTO Operation.MerchStopCheckOut(MerchStopID, ClientCheckOutTime, ClientCheckOutTimeZone, CheckOutLatitude,
			CheckOutLongitude, CasesHandeled, CasesInBackroom, Comments, AtAccountTimeInMinute, UTCInsertTime, UTCUpdateTime, CheckOutDistanceInMiles)
			VALUES(@CheckInMerchStopID, @ClientCheckOutTime, @ClientCheckOutTimeZone, @CheckOutLatitude,
			@CheckOutLongitude, @CasesHandeled, @CasesInBackroom, @Comments, @AtAccountTimeInMinute, SysUTCDateTime(), SysUTCDateTime(), dbo.udfDistanceInMiles(@StoreLat, @StoreLong, @CheckOutLatitude, @CheckOutLongitude))

		END
	ELSE IF (@CheckInMerchStopID is not null)
		BEGIN
		  UPDATE Operation.MerchStopCheckOut
		    SET CasesHandeled = @CasesHandeled, CasesInBackroom = @CasesInBackroom, Comments = @Comments, UTCUpdateTime = SysUTCDateTime(), 
				CheckOutDistanceInMiles = dbo.udfDistanceInMiles(@StoreLat, @StoreLong, @CheckOutLatitude, @CheckOutLongitude)
		  WHERE MerchStopID = @CheckInMerchStopID			
		END
	Else If(@CheckInMerchStopID is null)
		Begin
			RAISERROR ('No Checkin record found', -- Message text.  
               16, -- Severity.  
               1 -- State.  
               );  
	End

	---Update StoreVisitStatus value bcause user has checkedin in store	
	If (@CheckInMerchStopID is not null)
	Begin
		 UPDATE Planning.Dispatch 	 
			 SET StoreVisitStatusID = 3
		 WHERE DispatchDate = @DispatchDate 
				AND GSN = @GSN 		
				AND SAPAccountNumber = @SAPAccountNumber			
				And InvalidatedBatchID is null
				AND SameStoreSequence  = @SameStoreSequence  
				--And StoreVisitStatusID = 2 -- Took out at 1/9/2017
				And MerchGroupID = @MerchGroupID
				--And RouteID = @RouteID     -- Took out at 1/9/2017
				-- 1/9 update makes sure all the account with the same sequence are labeled as visited, regardless of Valid entry or not
			
		---- Insert/Update data in GSN Activity log table	
		IF EXISTS(
				SELECT * FROM Operation.GSNActivityLog
				WHERE GSN = @GSN AND SAPAccountNumber = @SAPAccountNumber AND Activity = 'Check Out' AND ClientTime = @ClientCheckOutTime AND ClientTimeZone = @ClientCheckOutTimeZone
				)
			BEGIN
				UPDATE Operation.GSNActivityLog 
					SET UTCUpdateTime = SysUTCDateTime()
					WHERE GSN = @GSN AND SAPAccountNumber = @SAPAccountNumber AND Activity = 'Check Out' AND ClientTime = @ClientCheckOutTime AND ClientTimeZone = @ClientCheckOutTimeZone
			END
		ELSE
			BEGIN		
				INSERT INTO Operation.GSNActivityLog (OperationDate, GSN, SAPAccountNumber, Activity, ClientTime,ClientTimeZone, 
				UTCInsertTime, UTCUpdateTime)
				VALUES (@DispatchDate, @GSN, @SAPAccountNumber, 'Check Out', @ClientCheckOutTime, @ClientCheckOutTimeZone, SysUTCDateTime(), SysUTCDateTime())			
			END
		End

	END
Go

Print 'Operation.pInsertMerchStopCheckOut updated at ' + convert(varchar(200), GetDate())
Go
