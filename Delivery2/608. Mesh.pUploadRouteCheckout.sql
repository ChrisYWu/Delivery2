USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pUploadRouteCheckout')
Begin
	Drop Proc Mesh.pUploadRouteCheckout
	Print '* Mesh.pUploadRouteCheckout'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec Mesh.pUploadRouteCheckout @DeliveryDateUTC = '2018-03-02', @RouteID = 100411010
exec Mesh.pUploadRouteCheckout @RouteID = 110901504

{ 
	DeliveryDateUTC: "2018-02-15T00:00:00", 
	RouteID: 100411010,
	ActualStartTime: "2018-02-21T18:10:30",
	ActualStartGSN: "WUXYX002",
	FirstName: "Chris",
	LastName: "Wu",
	PhoneNumber: "972-333-0000",
	Latitude: 42.595788,
	Longitude: -94.998123,
	LastModifiedUTC: "2018-02-21T18:25:07"
}

{ 
	DeliveryDateUTC: "2018-03-02T00:00:00", 
	RouteID: 100411010, 
	ActualStartTime: "2018-03-02T11:45:12", 
	ActualStartGSN: "WUXYX003", 
	FirstName: "Chris", 
	LastName: "Dev", 
	PhoneNumber: "972-333-0000", 
	Latitude: 42.595788, 
	Longitude: -94.998123, 
	LastModifiedUTC: "2018-03-02T11:53:07" 
}

Select *
From 

*/

--Select *
--From Mesh.PlannedStop
--Where DeliveryDateUTC = '2018-03-02'
--And RouteID = 100411011
--Go

Create Proc Mesh.pUploadRouteCheckout
(
	@RouteID int,
	@ActualStartTime DateTime,
	@ActualStartGSN varchar(50),
	@FirstName varchar(50),
	@LastName varchar(50),
	@PhoneNumber varchar(50),
	@Latitude decimal(10, 7),
	@Longitude decimal(10, 7),
	@DeliveryDateUTC date = null,
	@LastModifiedUTC datetime2(0) = null
)
As
    Set NoCount On;

	Declare @OutputMessage varchar(100)
	Declare @DateString varchar(20)
		
	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())

	If @LastModifiedUTC is null
		Set @LastModifiedUTC = @ActualStartTime

	If Not Exists (Select DeliveryRouteID From Mesh.DeliveryRoute Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadRouteCheckout}: No route found for @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
		Return
	End

	If Not Exists ( Select *
		From Mesh.DeliveryStop
		Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadRouteCheckout}: Route manifest has not been fetched, or no stops scheduled for the route. @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
		Return
	End

	--If Not Exists (Select DeliveryRouteID From Mesh.DeliveryRoute Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC And IsStarted = 1)
	--Begin
		Update Mesh.DeliveryRoute
			Set ActualStartTime = @ActualStartTime,
				ActualStartGSN = @ActualStartGSN,
				ActualStartFirstname = @FirstName,
				ActualStartLastName	= @LastName,
				ActualStartPhoneNumber = @PhoneNumber,
				ActualStartLatitude = @Latitude,
				ActualStartLongitude = @Longitude,
				LastModifiedBy = @ActualStartGSN,
				LastModifiedUTC = @LastModifiedUTC,
				LocalSynctime = GetDate()
		Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC
		Set @OutputMessage = 'OK'
	--End
	--Else 
	--Begin
	--	Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
	--	RAISERROR (N'[ClientDataError]{Mesh.pUploadRouteCheckout}: Route has been checked out. @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
	--		16, -- Severity,  
	--		1, -- State,  
	--		@RouteID, -- First argument.  
	--		@DateString); -- Second argument.  
	--End
GO

Print 'Mesh.pUploadRouteCheckout created'
Go

--
exec Mesh.pUploadRouteCheckout @DeliveryDateUTC = '2018-03-28', @RouteID = 110901504,
	@ActualStartTime = '2018-02-21 18:09:30',
	@ActualStartGSN = 'WUXYX002',
	@FirstName = 'Chris',
	@LastName = 'Wu',
	@PhoneNumber = '972-333-0000',
	@Latitude = 42.595700,
	@Longitude = -94.998000,
	@LastModifiedUTC = '2018-02-21 18:10:44'




