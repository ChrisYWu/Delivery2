USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pUploadStopDNS')
Begin
	Drop Proc Mesh.pUploadStopDNS
	Print '* Mesh.pUploadStopDNS'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc Mesh.pUploadStopDNS
(
	@DeliveryStopID int,
	@DNSReasonCode varchar(50),
	@DNSReason varchar(50) = null,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------	
	If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS not found @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And CheckInTime is not Null))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS is already checked-in @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And StopType = 'STP'))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS is not of type "STP" @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And DNS = 1))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pUploadStopDNS}: Stop requested for DNS is DNSed already @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else 
	Begin
		Update ds Set
		ds.DNSReasonCode = @DNSReasonCode
		,ds.DNSReason = @DNSReason
		,ds.LastModifiedBy = @LastModifiedBy
		,ds.LastModifiedUTC = @LastModifiedUTC
		,ds.LocalUpdateTime = SysDateTime()
		From Mesh.DeliveryStop ds
		Where ds.DeliveryStopID = @DeliveryStopID

	End
Go

Print 'Mesh.pUploadStopDNS created'
Go

----
----
-------------------------------
Declare @CurrentDate DateTime
Set @CurrentDate = SysUTCDateTime()

exec Mesh.pUploadStopDNS
	@DeliveryStopID = 1491,
	@DNSReasonCode = 'ER',
	@DNSReason = 'Some Text' ,
	@LastModifiedBy = 'WUXYX003', 
	@LastModifiedUTC = @CurrentDate


Select * 
From Mesh.DeliveryStop
Where DeliveryDateUTc = '2018-04-30'
And RouteID = 111501301
Order By Sequence 
