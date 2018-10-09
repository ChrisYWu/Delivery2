USE [Portal_Data]
GO

/****** Object:  StoredProcedure [Playbook].[pSaveDSDPromotion]    Script Date: 3/10/2017 9:34:53 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
exec Playbook.pSaveDSDPromotion @PromotionID = 16402


--- Hier Only
Select * 
From PreCal.PromotionBranch
Where PromotionID = 59433

exec Playbook.pSaveDSDPromotion @PromotionID = 59433, @Debug = 1

--- Hier Only
Select * 
From PreCal.PromotionBranch
Where PromotionID = 64292

exec Playbook.pSaveDSDPromotion @PromotionID = 64292, @Debug = 1

--- State and Hier 41652
Select * 
From PreCal.PromotionBranch
Where PromotionID = 41652

exec Playbook.pSaveDSDPromotion @PromotionID = 41652, @Debug = 1

--- State and Hier 35661
Select * 
From PreCal.PromotionBranch
Where PromotionID = 35661

exec Playbook.pSaveDSDPromotion @PromotionID = 35661, @Debug = 1

--- State and Hier 36816
Select * 
From PreCal.PromotionBranch
Where PromotionID = 36816

Select * 
From PreCal.PromotionBranchChainGroup
Where PromotionID = 36816

exec Playbook.pSaveDSDPromotion @PromotionID = 36816, @Debug = 1

--- State Only 33704
Select * 
From PreCal.PromotionBranch
Where PromotionID = 33704

exec Playbook.pSaveDSDPromotion @PromotionID = 33704, @Debug = 1

---
Select *
From PlayBook.PromotionGeoRelevancy
Where Coalesce(BUID, RegionID, AreaID, BranchID, 0) = 0
And PromotionID in 
(	Select Distinct PromotionID
	From PlayBook.PromotionGeoRelevancy
	Where Coalesce(StateID, 0) > 0
)
Order By PromotionID Desc

Select * From PlayBook.PromotionGeoRelevancy
Where PromotionID = 33704

*/

ALTER Proc [Playbook].[pSaveDSDPromotion]
(
	@PromotionID int,
	@Debug bit = 0
)
AS
Begin
	Set NoCount On;

	If (@Debug = 1)
	Begin
		Declare @StartTime DateTime2(7)
		Set @StartTime = SYSDATETIME()

		Select '---- Starting ----' Debug, @PromotionID PromotionID
	End

	--- GeoRelevancy Expansion with Date Cut
	Declare @PromoGeoR Table 
	(
		BUID int,
		RegionID int, 
		AreaID int,
		BranchID int,
		StateID int,
		HierDefined int,
		StateDefined int,
		TYP int  -- Type of Promotion, 1 Init; 2 State And Hier; 3 HierOnly; 4 StateOnly; 5 AnytingElse; 6 Assume All DSD Promotion For StateOnly
	)

	Insert Into @PromoGeoR
	Select BUID, RegionID, AreaID, BranchID, StateID, 
		Case When (Coalesce(Case When BUID < 1 Then Null Else BUID End, 
			Case When RegionID < 1 Then Null Else RegionID End, 
			Case When AreaID < 1 Then Null Else AreaID End, 
			Case When BranchID < 1 Then Null Else BranchID End, 0) > 0) Then 1 Else 0 End HierDefined, 
		Case When (Coalesce(StateID, 0) > 0) Then 1 Else 0 End StateDefined,
		1 TYP 
	From Playbook.PromotionGeoRelevancy pgr
	Join Playbook.RetailPromotion rp on pgr.PromotionID = rp.PromotionID
	Where (
		Coalesce(
			Case When BUID < 1 Then Null Else BUID End, 
			Case When RegionID < 1 Then Null Else RegionID End, 
			Case When AreaID < 1 Then Null Else AreaID End, 
			Case When BranchID < 1 Then Null Else BranchID End, 0) > 0
	)
	And pgr.PromotionID = @PromotionID

	If (@Debug = 1)
	Begin
		Select '---- Creating @PromoGeoR Table done----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * From @PromoGeoR
	End

	-- 1 Init; 2 State And Hier; 3 HierOnly; 4 StateOnly; 5 AnytingElse; 6 Assume All DSD Promotion For StateOnly
	Declare @HierDefined int
	Declare @StateDefined int

	Select @HierDefined = Sum(HierDefined), @StateDefined = Sum(StateDefined)
	From @PromoGeoR

	Update pgr
	Set TYP = Case When @HierDefined > 0 And @StateDefined  > 0 Then 2 When @HierDefined > 0 Then 3 When @StateDefined > 0 Then 4 Else 5 End
	From @PromoGeoR pgr


	-- Note: This is a cross join, for state only promotions, we add all the BUs to them
	If Exists (Select * From @PromoGeoR Where TYP = 4)
	Begin
		Insert Into @PromoGeoR(BUID, TYP)
		Select BUID, 6
		From SAP.BusinessUnit
	End

	-- Now there is no State-Only Promotions, they are converted to be State and Hier Promotions
	Update @PromoGeoR
	Set TYP = 2
	Where TYP in (4,6)

	If (@Debug = 1)
	Begin
		Select '---- Promotion Classification done----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select *, 
		Case When TYP = 2 Then 'State And Hier'
			When TYP = 3 Then 'Hier Only'
			When TYP = 4 Then 'State Only'
		End PromotionType
		From @PromoGeoR temp
	End

	--- Branch Driver table -----
	Declare @PGR Table 
	(
		PromotionID int not null,
		BranchID int
		Primary Key (PromotionID, BranchID)
	)

	-- Hier Only
	Insert Into @PGR(PromotionID, BranchID)
	Select @PromotionID, v.BranchID
	From @PromoGeoR pgr
	Join PreCal.DSDBranch v on pgr.BUID = v.BUID
	Where TYP = 3
	Union
	Select @PromotionID, v.BranchID
	from @PromoGeoR pgr
	Join PreCal.DSDBranch v on pgr.RegionID = v.RegionID
	Where TYP = 3 And Coalesce(pgr.BUID, 0) = 0
	Union
	Select @PromotionID, v.BranchID
	from @PromoGeoR pgr
	Join PreCal.DSDBranch v on pgr.AreaID = v.AreaID
	Where TYP = 3 And Coalesce(pgr.BUID, pgr.RegionID, 0) = 0
	Union
	Select @PromotionID, pgr.BranchID
	From @PromoGeoR pgr
	Where TYP = 3 And Coalesce(pgr.BranchID, 0) > 0

	If (@Debug = 1)
	Begin
		Select '---- Type 3(Hier Only) Expanded ----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * From @PGR
	End

	-- State & Hier
	Insert Into @PGR(PromotionID, BranchID)
	Select @PromotionID, r.BranchID
	From (
		Select v.BranchID
		From @PromoGeoR pgr
		Join PreCal.DSDBranch v on pgr.BUID = v.BUID
		Where TYP = 2
		Union
		Select v.BranchID
		from @PromoGeoR pgr
		Join PreCal.DSDBranch v on pgr.RegionId = v.RegionId
		Where TYP = 2 And pgr.BUID is null
		Union
		Select v.BranchID
		from @PromoGeoR pgr
		Join PreCal.DSDBranch v on pgr.AreaId = v.AreaId
		Where TYP = 2 And Coalesce(pgr.BUID, pgr.RegionId, 0) = 0
		Union
		Select pgr.BranchID
		From @PromoGeoR pgr
		Where TYP = 2 And Coalesce(pgr.BranchID, 0) > 0
	) l
	Join (
		Select Distinct h.BranchID
		From @PromoGeoR pgr
		Join PreCal.BranchState h on pgr.StateID = h.StateRegionID
		Where TYP = 2) r On l.BranchID = r.BranchID
	
	If (@Debug = 1)
	Begin
		Select '---- All Expansions(both type 2 and 3) done ----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * From @PGR
	End

	--- Filtering
	--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Declare @PGR1 Table 
	(
		PromotionID int not null,
		BranchID int
		Primary Key (PromotionID, BranchID)
	)

	--- First by brand ---
	Insert Into @PGR1
	Select Distinct pgr.PromotionID, pgr.BranchID
	From PreCal.BranchBrand bb, -- Branch Brand Association
	(
		Select Distinct PromotionID, b.BrandID
		From Playbook.PromotionBrand pb With (nolock)
		Join SAP.Brand b on (pb.TrademarkID = b.TrademarkID)
		Union
		Select PromotionID, BrandID
		From Playbook.PromotionBrand With (nolock) Where Coalesce(TradeMarkID, 0) = 0 
	) ptm, -- Promotion Brand
	@PGR pgr  --Promotion Geo
	Where pgr.BranchID = bb.BranchID
	And bb.BrandID = ptm.BrandID
	And pgr.PromotionID = ptm.PromotionID
	
	If (@Debug = 1)
	Begin
		Select '---- Promotion filtered by Brands ----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * From @PGR1
	End

	--- Then by chain ---
	Delete From @PGR

	Insert Into @PGR
	Select Distinct pgr.PromotionID, pgr.BranchID
	From 	
	@PGR1 pgr, -- Promotion Geo
	Precal.PromotionLocalChain pc, --- Promotion Chain
	Shared.tLocationChain tlc,  -- This table was created by Jag and used in production reliably
	Playbook.RetailPromotion rp
	Where pgr.BranchID = tlc.BranchID
	And tlc.LocalChainID = pc.LocalChainID
	And pc.PromotionID = pgr.PromotionID
	And rp.PromotionID = pgr.PromotionID
	Union
	Select Distinct pgr.PromotionID, pgr.BranchID
	From 	
	@PGR1 pgr, --- Promotion Geo
	(
		Select PromotionID, ChannelID
		From Playbook.PromotionChannel
		Where isnull(ChannelID, 0) > 0
		Union
		Select Distinct PromotionID, c.ChannelID
		From Playbook.PromotionChannel pc
		Join SAP.Channel c on pc.SuperChannelID = c.SuperChannelID
		Where isnull(pc.SuperChannelID, 0) > 0
	) pc, --- Promotion Chain
	PreCal.BranchChannel tlc,  -- This table was created by Jag and used in production reliably
	Playbook.RetailPromotion rp
	Where pgr.BranchID = tlc.BranchID
	And tlc.ChannelID = pc.ChannelID
	And pc.PromotionID = pgr.PromotionID
	And rp.PromotionID = pgr.PromotionID

	If (@Debug = 1)
	Begin
		Select '---- Promotion further filtered further by Chains Or Channels ----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * From @PGR
	End
	--~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

	----- Commiting -----
	Begin Transaction
		Delete PreCal.PromotionBranch
		Where PromotionID = @PromotionID

		Insert Into PreCal.PromotionBranch(BranchID, PromotionID, PromotionStartDate, PromotionEndDate, IsPromotion, PromotionGroupID)
		Select pgr.BranchID, pgr.PromotionID, rp.PromotionStartDate, rp.PromotionEndDate, Case When rp.InformationCategory = 'Promotion' Then 1 Else 0 End IsPromotion, PromotionGroupID
		From @PGR pgr
		Join Playbook.RetailPromotion rp on pgr.PromotionID = rp.PromotionID

		Delete PreCal.PromotionBranchChainGroup
		Where PromotionID = @PromotionID

		Insert Into PreCal.PromotionBranchChainGroup(PromotionID, BranchID, PromotionStartDate, PromotionEndDate, IsPromotion, ChainGroupID)
		Select pb.PromotionID, pb.BranchID, pb.PromotionStartDate, pb.PromotionEndDate, pb.IsPromotion, pcg.ChainGroupID
		From PreCal.PromotionBranch pb with (nolock)
		Join PreCal.PromotionChainGroup pcg on pb.PromotionID = pcg.PromotionID
		Join PreCal.BranchChainGroup bcg on bcg.BranchID = pb.BranchID and bcg.ChainGroupID = pcg.ChainGroupID
		Where pb.PromotionID = @PromotionID

		Delete PreCal.PromotionChannel
		Where PromotionID = @PromotionID

		Insert PreCal.PromotionChannel(PromotionID, ChannelID)
		Select Distinct PromotionID, c.ChannelID
		From Playbook.PromotionChannel pc
		Join SAP.Channel c on pc.SuperChannelID = c.SuperChannelID
		Where pc.PromotionID = @PromotionID
		Union
		Select PromotionID, ChannelID
		From Playbook.PromotionChannel pc
		Where ChannelID is not null
		And pc.PromotionID = @PromotionID

	Commit Transaction

	If (@Debug = 1)
	Begin
		Select '---- Commiting done. That''s it ----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * 
		From PreCal.PromotionBranchChainGroup
		Where PromotionID = @PromotionID

		Select * 
		From PreCal.PromotionChannel
		Where PromotionID = @PromotionID
	End

End

GO

