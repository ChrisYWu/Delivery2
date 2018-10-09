USE [Merch]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


/*

EXEC [Operation].[pInsertMerchStopCheckIn]
	 @DispatchDate = '2018-09-26'
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
