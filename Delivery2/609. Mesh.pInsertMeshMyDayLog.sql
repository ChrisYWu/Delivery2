USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pInsertMeshMyDayLog')
Begin
	Drop Proc Mesh.pInsertMeshMyDayLog
	Print '* Mesh.pInsertMeshMyDayLog'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/


Create Proc Mesh.pInsertMeshMyDayLog
(
	@WebEndPoint varchar(50)
	,@StoredProc varchar(50)
	,@CorrelationID varchar(32) = null
	,@GetParameters varchar(200) = null
	,@PostJson varchar(max) = null
	,@DeliveryDateUTC date = null
	,@RouteID int = null
	,@GSN varchar(50) = null
)
As
    Set NoCount On;

	If Exists (Select Value From Setup.Config Where [Key] = 'MeshMyDayLog' and Value = '1')
	Begin
		Insert Into Mesh.MyDayActivityLog
				   (WebEndPoint
				   ,StoredProc
				   ,GetParemeters
				   ,PostJson
				   ,RequestTime
				   ,CorrelationID
				   ,DeliveryDateUTC
				   ,RouteID
				   ,GSN)
			 VALUES
				   (@WebEndPoint, 
				   @StoredProc, 
				   @GetParameters, 
				   @PostJson, 
				   SysDateTime()
				   ,@CorrelationID
				   ,@DeliveryDateUTC
				   ,@RouteID
				   ,@GSN)
	End

	If (Datepart(dw, GetDate()) = 1) -- 1 is Sunday 
	Begin
		Declare @Cnt Int
		Select @Cnt = Count(*) From Mesh.MyDayActivityLog

		If (@Cnt > 150000)  -- Total Number Records > 150K 
		Begin
			Declare @CutOffDate Date
			Select @CutOffDate = DateAdd(Day, -60, GetDate())  -- CutOff to two month

			Select @CutOffDate
			Delete Mesh.MyDayActivityLog Where DeliveryDateUTC < @CutOffDate
		End
	End

GO

Print 'Mesh.pInsertMeshMyDayLog created'
Go

--



