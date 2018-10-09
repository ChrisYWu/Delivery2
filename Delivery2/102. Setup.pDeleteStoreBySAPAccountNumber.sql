USE [Merch]
GO

/****** Object:  StoredProcedure [Setup].[pDeleteStoreBySAPAccountNumber]    Script Date: 9/6/2018 10:30:28 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/*
-- Testing Range --
exec Setup.pDeleteStoreBySAPAccountNumber @SAPAccountNumber = 11286109, @MerchGroupID = 101, @GSN = 'WU---001'

--*/

ALTER Proc [Setup].[pDeleteStoreBySAPAccountNumber]
(
	@SAPAccountNumber bigint,
	@MerchGroupID int,
	@GSN varchar(100)
)
AS

Begin
	Set NoCount On;
	
	Begin Try
        Begin Transaction
	   	--- Delete From Plan ---
		--- a. Delete
		Declare @RSW Table
		(
			RouteID int,
			MerchGroupID int,
			DayOfWeek int
		)

		Delete
		From Planning.RouteStoreWeekday
		Output Deleted.RouteID, Deleted.MerchGroupID, Deleted.DayOfWeek Into @RSW 
		Where SAPAccountNumber = @SAPAccountNumber
		--And MerchGroupID = @MerchGroupID

		Declare @RSWDistinct Table
		(
			RouteID int,
			MerchGroupID int,
			DayOfWeek int
		)

		Insert Into @RSWDistinct
		Select Distinct RouteID, MerchGroupID, DayOfWeek
		From @RSW

		--- b. Reset sequence
		If(@@rowcount > 0)
			Begin
			Update rsw
			Set rsw.Sequence = t.NewSequence,
				LastModified = SysUTCDatetime(),
				LastModifiedBy = @GSN
			From Planning.RouteStoreWeekday rsw
			Join
			(
				Select rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek, Sequence, SAPAccountNumber,
						Row_Number() Over (Partition By rsw.RouteID, rsw.MerchGroupID, rsw.DayOfWeek Order By Sequence) NewSequence
				From Planning.RouteStoreWeekday rsw
				Join @RSWDistinct rd on rsw.RouteID = rd.RouteID And rsw.MerchGroupID = rd.MerchGroupID And rsw.DayOfWeek = rd.DayOfWeek
			) t
			On rsw.RouteID = t.RouteID And rsw.MerchGroupID = rsw.MerchGroupID And rsw.DayOfWeek = t.DayOfWeek And rsw.Sequence = t.Sequence
		End
		--------------------------

		--- Delete From PreDispatch from today on ---
		Declare @TodayDate Date
		Set @TodayDate = Convert(Date, GetDate())


		--- a0. Pre-Delete and determine publishing status ---
		Declare @Action Table 
		(
			DispatchDate Date,
			MerchGroupID int,
			StatusID int -- 0: Initialization; 1:Error; 2:Preview; 3:Saved; 4:Scheduled
		)

		Insert Into @Action
		Select Distinct DispatchDate, MerchGroupID, 0
		From Planning.PreDispatch
		Where SAPAccountNumber = @SAPAccountNumber
		And DispatchDate >= @TodayDate
		--And MerchGroupID = @MerchGroupID

		Declare @retCode int
		Declare @DispatchDate Date
		Declare @MerchGroupIDFromCursor Int

		Declare Dispatch_Cursor Cursor For
		Select Distinct DispatchDate, MerchGroupID
		From @Action

		Open Dispatch_Cursor
		Fetch Next From Dispatch_Cursor Into @DispatchDate, @MerchGroupIDFromCursor
		
		While @@Fetch_Status = 0
		Begin
			exec @retCode = Planning.pGetScheduleStatus @MerchGroupIDFromCursor, @DispatchDate, 0, 1
			Update @Action Set StatusID = @retCode Where DispatchDate = @DispatchDate And MerchGroupID = @MerchGroupIDFromCursor
			Fetch Next From Dispatch_Cursor Into @DispatchDate, @MerchGroupIDFromCursor
		End
		Close Dispatch_Cursor 
		Deallocate Dispatch_Cursor 

		-- Remove the preview record, leaving only the ones that need further updates or release
		Delete pd
		From Planning.PreDispatch pd
		Join @Action a on pd.MerchGroupID = a.MerchGroupID And pd.DispatchDate = a.DispatchDate And a.StatusID = 2
		-- Clean it out 
		Delete @Action Where StatusID = 2
	
		--- a. Delete
		Declare @Dis Table
		(
			MerchGroupID int,
			DispatchDate Date,
			RouteID int
		)

		Declare @Distinct Table
		(
			MerchGroupID int,
			DispatchDate Date,
			RouteID int
		)

		Delete Planning.PreDispatch
		Output Deleted.MerchGroupID, Deleted.DispatchDate, Deleted.RouteID Into @Dis
		Where SAPAccountNumber = @SAPAccountNumber
		And DispatchDate >= @TodayDate
		--And MerchGroupID = @MerchGroupID

		Insert Into @Distinct
		Select Distinct MerchGroupID, DispatchDate, RouteID From @Dis

		--- b. Reset sequence
		If(@@rowcount > 0)
		Begin
			-- There are future PreDispatch that are impacted by the previous delete, so need to adjust the sequence for affected route/day combination	
			Update pd
			Set pd.Sequence = t.NewSequence,
			LastModified = SysUTCDateTime(),
			LastModifiedBy = @GSN
			From Planning.PreDispatch pd
			Join
			(
				Select pd.DispatchDate, pd.MerchGroupID, pd.RouteID, pd.Sequence, pd.GSN, pd.SAPAccountNumber,
					Row_Number() Over (Partition By pd.DispatchDate, pd.MerchGroupID, pd.RouteID Order By Sequence) NewSequence
				From Planning.PreDispatch pd
				Join @Distinct d
				On pd.DispatchDate = d.DispatchDate And pd.MerchGroupID = d.MerchGroupID and pd.RouteID = d.RouteID
			) t
			on pd.RouteID = t.RouteID And pd.DispatchDate = t.DispatchDate And pd.GSN = t.GSN and pd.Sequence = t.Sequence and pd.SAPAccountNumber = t.SAPAccountNumber And pd.MerchGroupID = t.MerchGroupID


			If(@@rowcount = 0)
			-- The only SAPAccountNumber in a route is deleted and no row traces LastModified, so update the anchor row
			Begin
				Update pd
				Set LastModified = SysUTCDateTime(),
					LastModifiedBy = @GSN
				From Planning.PreDispatch pd
				Join @Distinct d
				On pd.DispatchDate = d.DispatchDate And pd.MerchGroupID = d.MerchGroupID
				Where pd.RouteID = -1
			End

			--No SameStoreSequence adjustment is needed since we delete one SAPAccountNumber from all future PreDispatches
		End

		--------------------------
		--- Delete From Dispatch from today on ---
		--- a. Select
		Declare @DispatchD Table
		(
			DispatchDate Date,
			MerchGroupID Int
		)

		Insert Into @DispatchD
		Select Distinct d.DispatchDate, d.MerchGroupID
		From Planning.Dispatch d 
		Join @Action a on d.DispatchDate = a.DispatchDate And a.StatusID = 4 And d.MerchGroupID = a.MerchGroupID
		Where SAPAccountNumber = @SAPAccountNumber
		And d.DispatchDate >= @TodayDate

		--- b. Re-schedule
		If(@@rowcount > 0)
		Begin	
			Declare @SystemNote varchar(200)
			Declare @AccountName varchar(200)
			Select @AccountName = AccountName from SAP.Account Where SAPAccountNumber = @SAPAccountNumber
			Set @SystemNote = 'System Note: Rescheduled after removing store :' + @AccountName + '(' + Convert(varchar(20), @SAPAccountNumber) + ')'

			Declare DispatchDate_Cursor Cursor For
			Select DispatchDate, MerchGroupID
			From @DispatchD

			Open DispatchDate_Cursor 
			Fetch Next From DispatchDate_Cursor Into @DispatchDate, @MerchGroupIDFromCursor
		
			While @@Fetch_Status = 0
			Begin
				exec Planning.pDispatch @MerchGroupID = @MerchGroupIDFromCursor, 
					@DispatchNote = @SystemNote, 
					@DispatchDate = @DispatchDate, 
					@ReleaseBy = @GSN
				Fetch Next From DispatchDate_Cursor Into @DispatchDate, @MerchGroupIDFromCursor
			End
			Close DispatchDate_Cursor 
			Deallocate DispatchDate_Cursor 
		End

		-------------------------------------------
		--- Delete the store setup ---
		Delete from Setup.Store where SAPAccountNumber = @SAPAccountNumber

       Commit
    End Try
    Begin Catch
      If @@TRANCOUNT > 0
         Rollback

      -- Raise an error with the details of the exception
      Declare @ErrMsg nvarchar(4000), @ErrSeverity int
      Select @ErrMsg = ERROR_MESSAGE(),
             @ErrSeverity = ERROR_SEVERITY()

      Raiserror(@ErrMsg, @ErrSeverity, 1)
    End Catch

End
Go