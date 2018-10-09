USE [Merch]
GO
/****** Object:  StoredProcedure [Operation].[pInsertBlob]    Script Date: 5/15/2018 3:28:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
Declare @Temp Bigint
Exec @Temp = Operation.pInsertBlob
	 @RelativeURL = '2016/09/14/default-636094429154152085.jpg'
	, @AbsoluteURL = 'https://mydpspoc.blob.core.windows.net/displaybuild/2016/09/14/default-736094429154152085.jpg'
	, @Container = 'displaybuild'
	, @StorageAccount = 'dpsappmerchandiser'

Select @Temp Temp

Need TESTING ---
*/

ALTER Proc Operation.pInsertBlob
(
	@RelativeURL varchar(250), 
	@AbsoluteURL varchar(250), 
	@Container varchar(250), 
	@StorageAccount varchar(250)
)
AS
BEGIN
	Set NoCount On
	----

	Declare @etval int
	Declare @NewBlobID bigint
	Declare @ContainerID int

	Select @ContainerID = ContainerID
	From Setup.AzureBlobContainer
	Where Container = @Container And StorageAccount = @StorageAccount

	If @ContainerID is null
	Begin
		Set @NewBlobID = -1
		RAISERROR ('No blob storage container found', -- Message text.  
        16, -- Severity.  
        1 -- State.  
        );  
	End
	Else If Exists (Select * From Operation.AzureBlobStorage Where @AbsoluteURL = AbsoluteURL)
	Begin
		Set @NewBlobID = -1
		-- RAISERROR ('Absolute URL exists, please request a new posting url and try again', 16, 1);  
	End
	Else
	Begin
		Insert Into Operation.AzureBlobStorage(ContainerID, RelativeURL, AbsoluteURL, IsOrphaned, LastModified)
		Values(@ContainerID, @RelativeURL, @AbsoluteURL, 0, SysDateTime())

		Select @NewBlobID = Scope_Identity();
	End

	Return @NewBlobID
END

