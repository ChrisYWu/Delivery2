USE [Merch]
GO

----- Trying to fix the existing sequence -----
Update rsw
Set rsw.Sequence = t.NewSequence,
	LastModified = SysUTCDatetime(),
	LastModifiedBy = 'System'
From Planning.RouteStoreWeekday rsw Join (
	Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
			Row_Number() Over (Partition By rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek Order By Sequence) NewSequence
	From Planning.RouteStoreWeekday rsw
) t
On rsw.RouteID = t.RouteID And rsw.MerchGroupID = t.MerchGroupID  And rsw.DayOfWeek = t.DayOfWeek And rsw.SAPAccountNumber = t.SAPAccountNumber And rsw.Sequence = t.Sequence
Go

Update pd
Set pd.Sequence = t.NewSequence,
LastModified = SysUTCDateTime(),
LastModifiedBy = 'System'
From Planning.PreDispatch pd Join (
	Select pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
		Row_Number() Over (Partition By pd.DispatchDate, pd.MerchGroupID, pd.RouteID Order By Sequence) NewSequence
	From Planning.PreDispatch pd
	Where RouteID <> -1
	And DispatchDate >= Convert(Date, GetDate())
) t
on pd.RouteID = t.RouteID And pd.DispatchDate = t.DispatchDate And pd.GSN = t.GSN and pd.Sequence = t.Sequence And pd.MerchGroupID = t.MerchGroupID
Go

-----------------------
ALTER Proc [Planning].[pRemoveStoreByWeekDay]
(
	@WeekDay int,
	@RouteID int,	
	@Sequence int,
	@LastModifiedBy varchar(50)	
)
AS

BEGIN

  	Delete Planning.RouteStoreWeekday 
	Where DayofWeek=@Weekday
	And RouteID = @RouteID
	And Sequence = @Sequence

	Update Planning.RouteStoreWeekday
	Set Sequence = Sequence - 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
	Where DayofWeek=@Weekday
	And RouteID = @RouteID
	And Sequence > @Sequence

	--Added to address the potential reseqeunce issue--
	Update rsw
	Set rsw.Sequence = t.NewSequence,
		LastModified = SysUTCDatetime(),
		LastModifiedBy = @LastModifiedBy
	From Planning.RouteStoreWeekday rsw Join (
		Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By rsw.RouteID, rsw.DayOfWeek Order By Sequence) NewSequence
		From Planning.RouteStoreWeekday rsw
		Where rsw.RouteID = @RouteID
	) t
	On rsw.RouteID = t.RouteID And rsw.MerchGroupID = t.MerchGroupID  And rsw.DayOfWeek = t.DayOfWeek And rsw.SAPAccountNumber = t.SAPAccountNumber And rsw.Sequence = t.Sequence
	--

END
Go

ALTER Proc [Planning].[pReassignStorebyWeekDay]
(
	@MerchGroupID int,
	@WeekDay int,
	@TargetRouteID int,
	@SourceRouteID int,
	@SAPAccountNumber bigint,
	@LastModifiedBy varchar(50),
	@Sequence int
)
AS

BEGIN

  ---Insert Store in TargetRouteID 
  DECLARE @NextSequence AS INT

  SELECT @NextSequence =  ISNULL(MAX(Sequence), 0) + 1   
  FROM Planning.RouteStoreWeekday
  WHERE RouteID=@TargetRouteID and MerchGroupID = @MerchGroupID and DayofWeek=@Weekday
 
  INSERT INTO  Planning.RouteStoreWeekday(RouteID, MerchGroupID, DayOfWeek, Sequence, SAPAccountNumber, LastModified, LastModifiedBy)
  VALUES (@TargetRouteID, @MerchGroupID, @Weekday, @NextSequence, @SAPAccountNumber, SysUTCDateTime(), @LastModifiedBy)

  --Remove store from SourceRouteID

  	Delete Planning.RouteStoreWeekday 
	Where DayofWeek=@Weekday
	And RouteID = @SourceRouteID
	And Sequence = @Sequence

	Update Planning.RouteStoreWeekday
	Set Sequence = Sequence - 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
	Where DayofWeek=@Weekday
	And RouteID = @SourceRouteID
	And Sequence > @Sequence

	
	--Added to address the potential reseqeunce issue--
	Update rsw
	Set rsw.Sequence = t.NewSequence,
		LastModified = SysUTCDatetime(),
		LastModifiedBy = @LastModifiedBy
	From Planning.RouteStoreWeekday rsw Join (
		Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By rsw.RouteID, rsw.DayOfWeek Order By Sequence) NewSequence
		From Planning.RouteStoreWeekday rsw
		Where rsw.MerchGroupID = @MerchGroupID
	) t
	On rsw.RouteID = t.RouteID And rsw.MerchGroupID = t.MerchGroupID  And rsw.DayOfWeek = t.DayOfWeek And rsw.SAPAccountNumber = t.SAPAccountNumber And rsw.Sequence = t.Sequence
	--
END
Go

ALTER Proc [Planning].[pUpdateStoreSequence]
(
	@WeekDay int,
	@RouteID int,
	@MoveFromSequence int,
	@MoveToSequence int,
	@LastModifiedBy varchar(50)
)

AS

BEGIN
	SET NOCOUNT ON;	

	Declare @Cache Table
	(
		WeekDay int,
		MerchGroupID int,
		RouteID int,
		Sequence int,	
		SAPAccountNumber bigint
	)

	INSERT INTO @Cache(WeekDay, MerchGroupID, RouteID, Sequence, SAPAccountNumber)
	SELECT DayOfWeek, MerchGroupID, RouteID, Sequence, SAPAccountNumber
	FROM Planning.RouteStoreWeekDay 
	WHERE DayOfWeek = @WeekDay
			AND RouteID = @RouteID
			AND Sequence = @MoveFromSequence

	DECLARE @MaxSeq Int

	SELECT @MaxSeq = Max(Sequence)
	FROM Planning.RouteStoreWeekDay 
	WHERE DayOfWeek = @WeekDay
		AND RouteID = @RouteID

	If (@MoveToSequence <= @MaxSeq)
	Begin
		If Exists (Select * From @Cache)
		Begin
			Delete Planning.RouteStoreWeekDay 
			Where DayOfWeek = @WeekDay
			And RouteID = @RouteID
			And Sequence = @MoveFromSequence

			Update Planning.RouteStoreWeekDay  
			Set Sequence = Sequence - 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
			Where DayOfWeek = @WeekDay
			And RouteID = @RouteID
			And Sequence > @MoveFromSequence

			Update Planning.RouteStoreWeekDay 
			Set Sequence = Sequence + 1, LastModified = SysUTCDateTime(), LastModifiedBy = @LastModifiedBy
			Where DayOfWeek = @WeekDay
			And RouteID = @RouteID
			And Sequence >= @MoveToSequence

			Insert Into Planning.RouteStoreWeekDay(DayOfWeek, MerchGroupID, RouteID, Sequence, SAPAccountNumber, LastModified, LastModifiedBy)
			Select WeekDay, MerchGroupID, RouteID, @MoveToSequence, SAPAccountNumber, SysUTCDateTime(), @LastModifiedBy
			From @Cache
		End
	End

	--Added to address the potential reseqeunce issue--
	Update rsw
	Set rsw.Sequence = t.NewSequence,
		LastModified = SysUTCDatetime(),
		LastModifiedBy = @LastModifiedBy
	From Planning.RouteStoreWeekday rsw Join (
		Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
				Row_Number() Over (Partition By rsw.RouteID, rsw.DayOfWeek Order By Sequence) NewSequence
		From Planning.RouteStoreWeekday rsw
		Where rsw.RouteID = @RouteID
	) t
	On rsw.RouteID = t.RouteID And rsw.MerchGroupID = t.MerchGroupID  And rsw.DayOfWeek = t.DayOfWeek And rsw.SAPAccountNumber = t.SAPAccountNumber And rsw.Sequence = t.Sequence
	--

	SELECT DayOfWeek, MerchGroupID, RouteID, Sequence, SAPAccountNumber
	FROM Planning.RouteStoreWeekDay
	WHERE DayOfWeek = @WeekDay
		AND RouteID = @RouteID


END
Go

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

	--Added to address drag/drop sequence problem(20190327)--
	Update pd
	Set pd.Sequence = t.NewSequence,
	LastModified = SysUTCDateTime(),
	LastModifiedBy = @LastModifiedBy 
	--Select *
	From Planning.PreDispatch pd Join (
		Select pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
			Row_Number() Over (Partition By pd.DispatchDate, pd.RouteID Order By Sequence) NewSequence
		From Planning.PreDispatch pd
		Where pd.RouteID = @RouteID
		And DispatchDate >= @DispatchDate
	) t
	on pd.RouteID = t.RouteID And pd.DispatchDate = t.DispatchDate And pd.GSN = t.GSN and pd.Sequence = t.Sequence And pd.MerchGroupID = t.MerchGroupID
	--End added--

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
Go
