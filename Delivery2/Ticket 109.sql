use Merch
Go

Alter Table [Planning].[PreDispatch]
Add SameStoreSequence int null
Go

Update d
Set d.SameStoreSequence = t.SameStoreSequence
From Planning.PreDispatch d
Join (
	Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
		Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
	From Planning.PreDispatch
) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
exec Planning.pGetPreDispatch @MerchGroupID = 101, @GSN = 'System'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @ReleaseBy = 'WUXYX001'

exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-08-09', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-08-10', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-08-11', @ReleaseBy = 'WUXYX001'

exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-06-27', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-06-28', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-06-29', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-06-30', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-1', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-2', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-3', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-4', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-5', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-6', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-7', @ReleaseBy = 'WUXYX001'
exec Planning.pDispatch @MerchGroupID = 101, @DispatchNote = 'Wu Test', @DispatchDate = '2016-7-8', @ReleaseBy = 'WUXYX001'

exec Planning.pDispatch @MerchGroupID = 257, @DispatchNote = 'Wu Test 12', @DispatchDate = '2017-02-22', @ReleaseBy = 'WUXYX001'


Select *
From Planning.Dispatch
Where MerchGroupID = 101
And DispatchDate = '2016-10-13'
And GSN = 'TATWD001'

Select *
From Planning.PreDispatch
Where MerchGroupID = 101
And DispatchDate = '2016-10-13'
And GSN = 'TATWD001'

Update 
Planning.PreDispatch
Set SAPAccountNumber = 11989999
Where MerchGroupID = 101
And DispatchDate = '2016-10-13'
And GSN = 'TATWD001'
And Sequence = 4

--Select d.SAPAccountNumber, AccountName, SameStoreSequence, Max(StoreVisitStatusID) MaxStoreVisitStatusID, Min(StoreVisitStatusID) MinStoreVisitStatusID, Count(*) TotalCount
--From Planning.Dispatch d
--Join SAP.Account a on d.SAPAccountNumber = a.SAPAccountNumber
--Where GSN = 'CHARA001'
--And DispatchDate = Convert(Date, GetDate())
--Group By d.SAPAccountNumber, SameStoreSequence, AccountName

--Select *
--From Planning.Dispatch
--Where SAPAccountNumber = 11327268
--And GSN = 'CHARA001'
--And DispatchDate = Convert(Date, GetDate())

--Select d.SAPAccountNumber, AccountName, SameStoreSequence, Max(StoreVisitStatusID) MaxStoreVisitStatusID, Min(StoreVisitStatusID) MinStoreVisitStatusID, Count(*) TotalCount
--From Planning.Dispatch d
--Join SAP.Account a on d.SAPAccountNumber = a.SAPAccountNumber
--Where GSN = 'CHARA001'
--And DispatchDate = DateAdd(day, -3, Convert(Date, GetDate()))
--Group By d.SAPAccountNumber, SameStoreSequence, AccountName

*/


ALTER Proc [Planning].[pDispatch]
(
	@MerchGroupID int,
	@DispatchNote varchar(2000),
	@DispatchDate date = null,
	@ReleaseBy varchar(500)
)
As
Begin
	-------------------------------------
	Declare @BatchID Int
	Declare @DispatchInfo varchar(1000)
	Set @DispatchInfo = 'OK'

	If( @DispatchDate is null)
		Set @DispatchDate  = Convert(Date, GetDate())

	Begin Transaction;  
  
	Begin Try  
		-------------------------------------
		Insert Into Planning.DispatchBatch(MerchGroupID, DispatchDate, BatchNote, ReleaseTime, ReleaedBy)
		Values(@MerchGroupID, @DispatchDate, @DispatchNote, SYSUTCDATETIME(), @ReleaseBy)

		Select @BatchID = SCOPE_IDENTITY();

		-------------------------------------
		With Dispatch As
		(
			Select * 
			From Planning.Dispatch 
			Where MerchGroupID = @MerchGroupID
			And DispatchDate = @DispatchDate
			And InvalidatedBatchID is null
		)

		Merge Dispatch as t
		Using (Select * From Planning.PreDispatch Where DispatchDate = @DispatchDate And MerchGroupID = @MerchGroupID) as s
		On (t.DispatchDate = s.DispatchDate And 
			t.MerchGroupID = s.MerchGroupID And 
			t.SAPAccountNumber = s.SAPAccountNumber And 
			t.SameStoreSequence = s.SameStoreSequence And 
			t.GSN = s.GSN And
			t.RouteID = s.RouteID)
		When Matched 
			Then Update Set
			t.Sequence = s.Sequence
		When Not Matched By Source And (t.DispatchDate = @DispatchDate And t.MerchGroupID = @MerchGroupID And t.InvalidatedBatchID is null)
			Then Update Set InvalidatedBatchID = @BatchID, LastModified = SYSUTCDATETIME(), LastModifiedBy = @ReleaseBy, ChangeNote = isnull(ChangeNote, '') + '*Invalided at batch ' + Convert(varchar(100), @BatchID)
		When Not Matched By Target
			Then Insert(DispatchDate, MerchGroupID, SAPAccountNumber, Sequence, SameStoreSequence, GSN, RouteID, BatchID, LastModified, LastModifiedBy, ChangeNote) 
			Values(s.DispatchDate, s.MerchGroupID, s.SAPAccountNumber, s.Sequence, s.SameStoreSequence, s.GSN, s.RouteID, @BatchID, SYSUTCDATETIME(), @ReleaseBy, '*Released at batch ' + Convert(varchar(100), @BatchID));
	End Try
	Begin Catch
		Select @DispatchInfo = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0  
			Rollback Transaction;  
	End Catch;
	
	IF @@TRANCOUNT > 0  
		Commit Transaction;  

	Select @DispatchInfo DispatchInfo, @BatchID BatchID
End
Go

/****** Object:  StoredProcedure [Planning].[pInsertStorePredispatch]    Script Date: 2/22/2017 1:16:07 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*

exec Planning.[pInsertStorePredispatch] @MerchGroupID = 101, @DispatchDate = '2016-06-11', @GSN = 'System'

*/

ALTER Proc [Planning].[pInsertStorePredispatch]
(
	@MerchGroupID int,
	@DispatchDate date = null,
	@GSN varchar(50),
	@RouteID int,
	@SAPAccountNumber int,
	@LastModifiedBy varchar(50)
)
As
begin	
	Declare @NextSequence as int
	SELECT @NextSequence = Isnull(Max(Sequence), 0) + 1
	FROM [Merch].[Planning].[PreDispatch]
	where RouteID=@RouteID and DispatchDate=@DispatchDate and GSN = @GSN

	Insert into [Planning].[PreDispatch]([DispatchDate],[MerchGroupID],[RouteID],[Sequence],[GSN],[SAPAccountNumber],[LastModified],[LastModifiedBy])
	Values (@DispatchDate, @MerchGroupID, @RouteID, @NextSequence, @GSN, @SAPAccountNumber, SysUTCDateTime(), @LastModifiedBy)

	Update d
	Set d.SameStoreSequence = t.SameStoreSequence
	From Planning.PreDispatch d
	Join (
		Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
			Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
		From Planning.PreDispatch
		Where MerchGroupID = @MerchGroupID And DispatchDate = @DispatchDate And GSN = @GSN And RouteID = @RouteID 
	) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID

end


/****** Object:  StoredProcedure [Planning].[pReSequenceStore]    Script Date: 2/22/2017 1:16:41 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
Select *
From Planning.PreDispatch
Where Dispatchdate = '2016-06-20'
And RouteID = 10123

exec Planning.pReSequenceStore 
	@DispatchDate = '2016-06-20',
	@RouteID = 10123,
	@MoveFromSequence = 1,
	@MoveToSequence = 3,
	@LastModifiedBy = 'System'

Select *
From Planning.PreDispatch
Where Dispatchdate = '2016-06-20'
And RouteID = 10123

*/

ALTER Proc [Planning].[pReSequenceStore]
(
	@DispatchDate date,
	@RouteID int,
	@MoveFromSequence int,
	@MoveToSequence int,
	@LastModifiedBy varchar(50)

)
As
Begin	
	Set NoCount On;

	Declare @Cache Table
	(
		DispatchDate date,
		MerchGroupID int,
		RouteID int,
		Sequence int,
		GSN varchar(50),
		SAPAccountNumber bigint
	)

	Insert Into @Cache(DispatchDate, MerchGroupID, RouteID, Sequence, GSN, SAPAccountNumber)
	Select DispatchDate, MerchGroupID, RouteID, Sequence, GSN, SAPAccountNumber
	From Planning.PreDispatch 
	Where DispatchDate = @DispatchDate
	And RouteID = @RouteID
	And Sequence = @MoveFromSequence

	Declare @MaxSeq Int

	Select @MaxSeq = Max(Sequence)
	From Planning.PreDispatch 
	Where DispatchDate = @DispatchDate
	And RouteID = @RouteID

	If (@MoveToSequence <= @MaxSeq)
	Begin
		If Exists (Select * From @Cache)
		Begin
			Delete Planning.PreDispatch 
			Where DispatchDate = @DispatchDate
			And RouteID = @RouteID
			And Sequence = @MoveFromSequence

			Update Planning.PreDispatch 
			Set Sequence = Sequence - 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
			Where DispatchDate = @DispatchDate
			And RouteID = @RouteID
			And Sequence > @MoveFromSequence

			Update Planning.PreDispatch 
			Set Sequence = Sequence + 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
			Where DispatchDate = @DispatchDate
			And RouteID = @RouteID
			And Sequence >= @MoveToSequence

			Insert Into Planning.PreDispatch(DispatchDate, MerchGroupID, RouteID, Sequence, GSN, SAPAccountNumber, LastModified, LastModifiedBy)
			Select DispatchDate, MerchGroupID, RouteID, @MoveToSequence, GSN, SAPAccountNumber, SysUTCDateTime(), @LastModifiedBy
			From @Cache
		End
	End

	Update d
	Set d.SameStoreSequence = t.SameStoreSequence
	From Planning.PreDispatch d
	Join (
		Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
			Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
		From Planning.PreDispatch
		Where RouteID = @RouteID And DispatchDate = @DispatchDate
	) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID


	Select DispatchDate, MerchGroupID, RouteID, Sequence, SAPAccountNumber
	From Planning.PreDispatch 
	Where DispatchDate = @DispatchDate
	And RouteID = @RouteID
End


GO

/****** Object:  StoredProcedure [Planning].[pRemoveStoreFromPreDispatch]    Script Date: 2/22/2017 1:19:11 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
Select *
From Planning.PreDispatch
Where Dispatchdate = '2016-06-20'
And RouteID = 10123

exec Planning.pRemoveStoreFromPreDispatch 
	@DispatchDate = '2016-06-11',
	@RouteID = 10123,
	@Sequence = 5,
	@LastModifiedBy = 'System'

*/

ALTER Proc [Planning].[pRemoveStoreFromPreDispatch]
(
	@DispatchDate date,
	@RouteID int,
	@Sequence int,
	@LastModifiedBy varchar(50)
)
As
Begin
	Set NoCount On;
		
	Delete Planning.PreDispatch 
	Where DispatchDate = @DispatchDate
	And RouteID = @RouteID
	And Sequence = @Sequence

	Update Planning.PreDispatch 
	Set Sequence = Sequence - 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
	Where DispatchDate = @DispatchDate
	And RouteID = @RouteID
	And Sequence > @Sequence

	Update d
	Set d.SameStoreSequence = t.SameStoreSequence
	From Planning.PreDispatch d
	Join (
		Select DisPatchDate, MerchGroupID, RouteID, GSN, Sequence, SAPAccountNumber,
			Row_Number() Over (Partition By MerchGroupID, DispatchDate, GSN, SAPAccountNumber Order By Sequence) SameStoreSequence
		From Planning.PreDispatch
		Where RouteID = @RouteID And DispatchDate = @DispatchDate
	) t on d.DispatchDate = t.DispatchDate And d.GSN = t.GSN and d.Sequence = t.Sequence and d.SAPAccountNumber = t.SAPAccountNumber And d.MerchGroupID = t.MerchGroupID

End
Go

--Select *
--From Setup.Merchandiser
--Where GSN = 'HICMX013'

--Select *
--From Planning.PreDispatch
--Where GSN = 'HICMX013'
--And DispatchDate = '2017-02-22'

--Select *
--From Planning.Dispatch
--Where GSN = 'HICMX013'
--And DispatchDate = '2017-02-22'

--Select *
--From Operation.MerchStopCheckIn
--Where GSN = 'HICMX013'
--And DispatchDate = '2017-02-22'

--Select *
--From Operation.MerchStoreSignature
--Where GSN = 'HICMX013'
--And DispatchDate = '2017-02-22'

