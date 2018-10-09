USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pCancelStopDNS')
Begin
	Drop Proc Mesh.pCancelStopDNS
	Print '* Mesh.pCancelStopDNS'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc Mesh.pCancelStopDNS
(
	@DeliveryStopID int,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------	
	If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pCancelStopDNS}: Stop requested for cancel DNS not found @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And StopType = 'STP'))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pCancelStopDNS}: Stop requested for cancel DNS is not of type "STP" @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else If (Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And DNS = 0))
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pCancelStopDNS}: Stop requested for cancel DNS is not DNSed to cancel @DeliveryStopID=%i', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID); -- First argument.  
	End
	Else 
	Begin
		Update ds Set
		ds.DNSReasonCode = null
		,ds.DNSReason = null
		,ds.LastModifiedBy = @LastModifiedBy
		,ds.LastModifiedUTC = @LastModifiedUTC
		,ds.LocalUpdateTime = SysDateTime()
		From Mesh.DeliveryStop ds
		Where ds.DeliveryStopID = @DeliveryStopID

	End
Go

Print 'Mesh.pCancelStopDNS created'
Go

----
----
-------------------------------
Declare @CurrentDate DateTime
Set @CurrentDate = SysUTCDateTime()

exec Mesh.pCancelStopDNS
	@DeliveryStopID = 1491,
	@LastModifiedBy = 'WUXYX003', 
	@LastModifiedUTC = @CurrentDate


Select * 
From Mesh.DeliveryStop
Where DeliveryDateUTc = '2018-04-30'
And RouteID = 111501301
Order By Sequence 
