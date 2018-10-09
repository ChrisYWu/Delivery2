use Portal_Data
Go

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('Shared.pPurgePromotions'))
Begin
	Drop Proc Shared.pPurgePromotions
	Print '* Shared.pPurgePromotions'
End
Go

/*
--
exec Shared.pPurgePromotions 36

*/

--Truncate Table Shared.ImageTobeDeleted
--Go

Create Proc Shared.pPurgePromotions
(
	@NumberOfMonthsCountBack int = 18
)

As
	Set NoCount On;

	If @NumberOfMonthsCountBack is null
		Set @NumberOfMonthsCountBack = 18

	Declare @CutOffDate Date
	Set @CutOffDate = DateAdd(Day, -30 * @NumberOfMonthsCountBack, Convert(Date, GetDate()))

	Declare @PromotionIDs Table
	(
		PromotionID int,
		PromotionEndDate date
	)

	Insert Into @PromotionIDs
	Select PromotionID, PromotionEndDate
	From Playbook.RetailPromotion
	Where PromotionEndDate < @CutOffDate
	--Where PromotionEndDate < '2015-12-17'
	Order By PromotionEndDate Desc

	Select * From @PromotionIDs 
	Order By PromotionEndDate Desc

	--Declare @POIStoreActivityCnt int
	--Declare @POIStoreDisplayCnt int
	--Declare @POIItemsOnDisplay int
	--Declare @POIImageConflict int

	--Select @POIStoreActivityCnt = Count(*)
	--From POI.StoreActivity
	--Where SurveyDate < @CutOffDate

	--Insert Into Shared.ImageTobeDeleted
	--(ImageURL, SourceTable, IDInSourceTable, RecordDeletionDate, DBServer, DBName, LastModified)
	--Select sd.ImageURL, 'POI.StoreDisplay' SourceTable, StoreDisplayID, SysDateTime(), 'BSCCAP108', 'Portal_Data', SysDateTime()
	--From POI.StoreActivity sa
	--Join POI.StoreDisplay sd on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate
	--Order By StoreDisplayID ASC

	--Select @POIStoreDisplayCnt = Count(Distinct StoreDisplayID)
	--From POI.StoreActivity sa
	--Join POI.StoreDisplay sd on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate
	
	--Select @POIItemsOnDisplay = Count(Distinct ItemsOnDisplayID)
	--From POI.ItemsOnDisplay od
	--Join POI.StoreDisplay sd on od.StoreDisplayID = sd.StoreDisplayID
	--Join POI.StoreActivity sa on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate


	--Select @POIImageConflict = Count(Distinct ImageConflictID)
	--From POI.ImageConflict ic
	--Join POI.StoreDisplay sd on ic.StoreDisplayID = sd.StoreDisplayID
	--Join POI.StoreActivity sa on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate
	

	--Select @NumberOfMonthsCountBack NumberOfMonthsCountBack, @CutOffDate CutOffDate,
	--	@POIStoreActivityCnt POIStoreActivityCnt,
	--	@POIStoreDisplayCnt POIStoreDisplayCnt,
	--	@POIItemsOnDisplay POIItemsOnDisplay,
	--	@POIImageConflict POIImageConflict

	--Delete od
	--From POI.ItemsOnDisplay od
	--Join POI.StoreDisplay sd on od.StoreDisplayID = sd.StoreDisplayID
	--Join POI.StoreActivity sa on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate

	--Delete ic
	--From POI.ImageConflict ic
	--Join POI.StoreDisplay sd on ic.StoreDisplayID = sd.StoreDisplayID
	--Join POI.StoreActivity sa on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate

	--Delete sd
	--From POI.StoreActivity sa
	--Join POI.StoreDisplay sd on sa.StoreActivityID = sd.StoreActivityID
	--Where SurveyDate < @CutOffDate

	--Delete
	--From POI.StoreActivity
	--Where SurveyDate < @CutOffDate

Go

Print 'Creating Shared.pPurgePromotions'
Go

