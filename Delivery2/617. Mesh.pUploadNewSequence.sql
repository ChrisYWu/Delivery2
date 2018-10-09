USE Merch
GO

If Exists (Select * From sys.procedures Where Name = 'pUploadNewSequence')
Begin
	Drop Proc Mesh.pUploadNewSequence
	Print '* Mesh.pUploadNewSequence'
End 
Go

----------------------------
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*

*/

Create Proc Mesh.pUploadNewSequence
(
	@RouteID int,
	@DeliveryDateUTC date = null,

	@ResequenceReasonIDs varchar(500),
	@AddtionalReason varchar(200),

	@Estimates Mesh.tEstimatedArrivals ReadOnly,
	@LastModifiedBy varchar(20),
	@LastModifiedUTC datetime2(0)
)
As
    Set NoCount On;

	----------------------------------------
	Declare @DateString varchar(20)
	
	If @DeliveryDateUTC is null
		Set @DeliveryDateUTC = convert(date, GetUTCDate())
	----------------------------------------

	Declare @MinSeq int, @MaxSeq int, @ResequenceID int

	----------------------------------------
	Select @MinSeq = Min(ds.Sequence), @MaxSeq = Max(ds.Sequence)
	From Mesh.DeliveryStop ds 
	Join @Estimates e on ds.DeliveryStopID = e.DeliveryStopID
	Where ds.Sequence <> e.Sequence

	Insert Into Mesh.Resequence
           (AddtionalReason
           ,RouteID
           ,DeliveryDateUTC
           ,StartSequenceID
           ,EndSequenceID
           ,LastModifiedBy
           ,LastModifiedUTC
           ,LocalUpdateTime)
     VALUES
           (@AddtionalReason
           ,@RouteID
           ,@DeliveryDateUTC
           ,@MinSeq
           ,@MaxSeq
           ,@LastModifiedBy 
           ,@LastModifiedUTC
           ,GetDate())

	Select @ResequenceID = Scope_Identity()
	----------------------------------------

	Insert Into Mesh.ResequeceReasons
           (ResequenceID
           ,ResequenceReasonID)
	Select @ResequenceID, Value ResequenceReasonID
	From Setup.udfSplit(@ResequenceReasonIDs, ',')
	----------------------------------------
	
	Insert Into Mesh.ResequenceDetail
			(ResequenceID
			,Sequence
			,OldEstimatedArrival
			,DeliveryStopID
			,NewSequence
			,NewEstimatedArrival)
	Select @ResequenceID, ds.Sequence,  Coalesce(ds.EstimatedArrivalTime, ds.PlannedArrival), e.DeliveryStopID, e.Sequence, e.EstimatedArrivalTime
	From Mesh.DeliveryStop ds 
	Join @Estimates e on ds.DeliveryStopID = e.DeliveryStopID
	Where ds.Sequence between Coalesce(@MinSeq, 0) and Coalesce(@Maxseq, 0)

	exec Mesh.pUpdateEstimatedArrivals @Estimates = @Estimates, @LastModifiedBy = @LastModifiedBy, @LastModifiedUTC = @LastModifiedUTC	

Go

Print 'Mesh.pUploadNewSequence created'
Go

----
----

Declare @Estimates Mesh.tEstimatedArrivals
Insert Into @Estimates
Values (
586, 5, '2018-03-02 12:38:01') --7 

Insert Into @Estimates
Values (
587, 6, '2018-03-02 13:08:01') --9 

Insert Into @Estimates
Values (
577, 7, '2018-03-02 13:36:01') --10

Insert Into @Estimates
Values (
585, 8, '2018-03-02 14:30:01') --5

Insert Into @Estimates
Values (
582, 9, '2018-03-02 15:15:01') --6

Insert Into @Estimates
Values (
584, 10, '2018-03-02 15:54:01') --8

Insert Into @Estimates
Values (
583, 11, '2018-03-02 16:34:01')

Insert Into @Estimates
Values (
580, 12, '2018-03-02 17:02:01')

-------------------------------
Declare @CurrentDate DateTime
Set @CurrentDate = SysUTCDateTime()

exec Mesh.pUploadNewSequence
	@RouteID = 100411011,
	@DeliveryDateUTC = '2018-03-02',
	@ResequenceReasonIDs = '1,3,2',
	@AddtionalReason = 'Something wrong with my front left tire',

	@Estimates = @Estimates, 
	@LastModifiedBy = 'WUXYX555', 
	@LastModifiedUTC = @CurrentDate

Select *
From Mesh.DeliveryStop
Where DeliveryDateUTc = '2018-03-02'
And RouteID = 100411011
Order By Sequence 
Go

Delete Mesh.DeliveryStop
Where DeliveryDateUTc = '2018-03-02'
And RouteID = 100411011
And Sequence > 12
Go