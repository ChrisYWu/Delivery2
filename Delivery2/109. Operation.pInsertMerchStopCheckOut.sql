USE [Merch]
GO

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

Select *
From Operation.MerchStopCheckIn
Where DispatchDate = '2016-07-06'

Select *
From Operation.GSNActivityLog
Where OperationDate = '2016-07-06'



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

Select *
From Operation.MerchStopCheckout
Where MerchStopID = 98

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

Print 'Export.pInsertMerchStopCheckOut updated at ' + convert(varchar(200), GetDate())
Go
