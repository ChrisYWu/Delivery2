use Portal_Data
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('Shared.pPurgeLogs'))
Begin
	Drop Proc Shared.pPurgeLogs
	Print '* Shared.pPurgeLogs'
End
Go

/*
--
exec Shared.pPurgeLogs 90

*/

Create Proc Shared.pPurgeLogs
(
	@NumberOfDaysCountBack int	
)

As
	Set NoCount On;

	Declare @BCMyDayWebServiceLogCnt int
	Declare @SharedExceptionLogCnt Int

	Select @BCMyDayWebServiceLogCnt = Count(*)  
	From BCMyDay.WebServiceLog 
	Where ModifiedDate > DateAdd(Day, -1 * @NumberOfDaysCountBack, Convert(Date, GetDate()))

	Select @SharedExceptionLogCnt = Count(*)  
	From Shared.ExceptionLog
	Where LastModified > DateAdd(Day, -1 * @NumberOfDaysCountBack, Convert(Date, GetDate()))
	
	Select Convert(Date, GetDate()) Today, DateAdd(Day, -1 * @NumberOfDaysCountBack, Convert(Date, GetDate())) CutOffDate,
			@BCMyDayWebServiceLogCnt RowsDeleted_BCMyDayWebServiceLog,
			@SharedExceptionLogCnt RowsDeleted_SharedExceptionLogCnt

	Delete
	From BCMyDay.WebServiceLog 
	Where ModifiedDate > DateAdd(Day, -1 * @NumberOfDaysCountBack, Convert(Date, GetDate()))
	
	Delete
	From Shared.ExceptionLog
	Where LastModified > DateAdd(Day, -1 * @NumberOfDaysCountBack, Convert(Date, GetDate()))
Go

Print 'Creating Shared.pPurgeLogs'
Go



