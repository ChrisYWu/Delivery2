USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pDeleteStop')
Begin
	Drop Proc Mesh.pDeleteStop
	Print '* Mesh.pDeleteStop'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec Mesh.pDeleteStop @DeliveryStopID = 1489

*/

Create Proc Mesh.pDeleteStop
(
	@DeliveryStopID int
)
As
    Set NoCount On;

	If Not Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID)
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pDeleteStop}: Stop @DeliveryStopID=%i is not found', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID);
	End
	Else If Exists (Select * From Mesh.DeliveryStop Where DeliveryStopID = @DeliveryStopID And IsAddedByDriver = 0)
	Begin
		RAISERROR (N'[ClientDataError]{Mesh.pDeleteStop}: Stop @DeliveryStopID=%i is not added by driver', -- Message text.  
           16, -- Severity,  
           1, -- State,  
           @DeliveryStopID);
	End
	Else 
	Begin
		Delete
		From Mesh.DeliveryStop
		Where DeliveryStopID = @DeliveryStopID
		And IsAddedByDriver = 1
	End
Go

Print 'Mesh.pDeleteStop created'
Go

--


