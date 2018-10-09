USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pUploadAddedStop')
Begin
	Drop Proc Mesh.pUploadAddedStop
	Print '* Mesh.pUploadAddedStop'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec Mesh.pUploadAddedStop 
	@DeliveryDateUTC = '2018-02-22', 
	@RouteID = 101600004, 
	@ServiceTime = 29, 
	@SAPAccountNumber=11219937, 
	@LastModifiedBy='WUXYX004', 
	@LastModifiedUTC='2018-05-21 12:33:44'

Select * From  Mesh.DeliveryStop
Where DeliveryStopID = 538

Delete Mesh.DeliveryStop
Where DeliveryStopID = 558

Select Max(DeliveryStopID)
From Mesh.DeliveryStop

*/

Create Proc Mesh.pUploadAddedStop
(
	@RouteID int,
	@ServiceTime int,
	@DeliveryDateUTC date = null,
	@StopType varchar(20) = 'STP',
	@SAPAccountNumber varchar(20) = null,
	@Quantity int = 0,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------
	Declare @DateString varchar(20)
	
	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())

	If LTrim(RTrim(@StopType)) = ''
		Set @StopType = 'STP'

	----------------------------------------
	Declare @SequenceMax int
	
	Select @SequenceMax = Coalesce(Max(Sequence), 1)
	From Mesh.DeliveryStop
	Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC

	----------------------------------------	
	If Not Exists (Select * From Mesh.DeliveryRoute
		Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadAddedStop}: No route found for @RouteID=%i and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @RouteID, -- First argument.  
           @DateString); -- Second argument.  
	End
	Else If Exists (Select DeliveryStopID From Mesh.DeliveryStop
				Where RouteID = @RouteID and @DeliveryDateUTC = DeliveryDateUTC and SAPAccountNumber = @SAPAccountNumber)
	Begin
		Set @DateString = Convert(varchar(20), @DeliveryDateUTC)
		RAISERROR (N'[ClientDataError]{Mesh.pUploadAddedStop}: Customer(%s) already exists in route (@RouteID=%i) and @DeliveryDateUTC=%s', -- Message text.  
           16, -- Severity,  
           1, -- State,  
		   @SAPAccountNumber, -- First argument.  
           @RouteID, -- Second argument.
           @DateString); -- 
	End
	Else
	Begin
		Declare @DeliveryStopID int
		Insert Into Mesh.DeliveryStop(DeliveryDateUTC, RouteID, Sequence, IsAddedByDriver, StopType, ServiceTime, SAPAccountNumber, 
			Quantity, LastModifiedBy, LastModifiedUTC, LocalUpdateTime)
		Values (@DeliveryDateUTC, @RouteID, @SequenceMax+1, 1, @StopType, @ServiceTime, @SAPAccountNumber, @Quantity, @LastModifiedby, @LastModifiedUTC, GetDate())

		Select @DeliveryStopID = Scope_Identity()

		Select @DeliveryStopID DeliveryStopID, d.SAPAccountNumber, Latitude, Longitude
		From Mesh.DeliveryStop d
		Left Join SAP.Account a on d.SAPAccountNumber = a.SAPAccountNumber
		Where DeliveryStopID = @DeliveryStopID

	End
Go

Print 'Mesh.pUploadAddedStop created'
Go

--
exec Mesh.pUploadAddedStop 
	@DeliveryDateUTC = '2016-12-12', 
	@RouteID = 100656103, 
	@ServiceTime = 1800, 
	@SAPAccountNumber=100656103, 
	@LastModifiedBy='MODSX001', 
	@LastModifiedUTC='2018-05-21 12:33:44'