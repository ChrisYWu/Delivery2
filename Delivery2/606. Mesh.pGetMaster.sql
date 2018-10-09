USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pGetMaster')
Begin
	Drop Proc Mesh.pGetMaster
	Print '* Mesh.pGetMaster'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
exec Mesh.pGetMaster

*/


Create Proc Mesh.pGetMaster
As
    Set NoCount On;

	Select FarawayReasonID, ReasonDesc
	From Mesh.FarawayReason
	Where IsActive = 1

	Select ResequenceReasonID, ReasonDesc
	From Mesh.ResequenceReason
	Where IsActive = 1

Go

Print 'Mesh.pGetMaster created'
Go

exec Mesh.pGetMaster
