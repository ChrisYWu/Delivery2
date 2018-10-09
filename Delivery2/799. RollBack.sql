USE [Portal_Data]
GO

/****** Object:  StoredProcedure [PreCal].[pRefreshLookups]    Script Date: 3/10/2017 11:30:18 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




ALTER Proc [PreCal].[pRefreshLookups]
As
Begin
	Set NoCount On

	-----
	Truncate Table PreCal.BottlerHier

	Insert Into PreCal.BottlerHier(SystemID, ZoneID, DivisionID, RegionID, BottlerID)
	Select v.SystemID, v.ZoneID, v.DivisionID, v.RegionID, b.BottlerID
	From BC.vSalesHierarchy v
	Join BC.Bottler b on b.BCRegionID = v.RegionID
	Where SystemID in (5, 6,7)

	-----
	Truncate Table PreCal.BottlerState

	Insert Into PreCal.BottlerState(BottlerID, StateRegionID)
	Select Distinct tmap.BottlerID, c.StateRegionID
	From BC.BottlerAccountTradeMark tmap
	Join SAP.Account a on a.AccountID = tmap.AccountID
	Join Shared.County c on a.CountyID = c.CountyID
	Where tmap.TerritoryTypeID <> 10
	And tmap.ProductTypeID = 1
	And a.CRMActive = 1

	-----
	Truncate Table PreCal.BranchState

	Insert Into PreCal.BranchState(BranchID, StateRegionID)
	Select a.BranchID, c.StateRegionID
	From SAP.Account a
	Join Shared.StateRegion c on a.State = c.RegionABRV
	Where a.Active = 1 --- This is DSD Active Flag
	Group By a.BranchID, c.StateRegionID
	Having Count(*) > 4   --- Threshhold for the bad data, 5 or more account to represent the state for any branch

	-----
	Truncate Table PreCal.DSDBranch

	Insert Into PreCal.DSDBranch(BUID, RegionID, AreaID, BranchID)
	Select BUID, RegionID, AreaID, BranchID
	From Mview.LocationHier

	-----
	Truncate Table PreCal.BranchBrand
	
	--Select Distinct b.BUID, b.RegionID, b.AreaID, bm.BranchID, m.BrandID
	--From SAP.BranchMaterial bm
	--Join SAP.Material m on bm.MaterialID = m.MaterialID
	--Join PreCal.DSDBranch b on bm.BranchID = b.BranchID
	
	Insert Into PreCal.BranchBrand(BUID, b.RegionID, b.AreaID, b.BranchID, BrandID)
	SELECT DISTINCT b.BUID, b.RegionID, b.AreaID, bm.BranchID, m.BrandID
	FROM SAP.BranchMaterial bm
	Join SAP.Material m ON bm.MaterialID = m.MaterialID
	Join PreCal.DSDBranch b ON bm.BranchID = b.BranchID
	join SAP.Package p  ON p.PackageID = m.PackageID
	WHERE p.PackageTypeID not in (SELECT PackageTypeID FROM SAP.PackageTypeExclusion)
	And MaterialStatusID <> 3

	-----
	Truncate Table PreCal.BranchChannel

	Insert Into PreCal.BranchChannel(BranchID, ChannelID)
	Select Distinct BranchID, ChannelID
	From SAP.Account a
	Where BranchID is not null
	And ChannelID is not null
	And Active = 1

	-----
	Truncate Table PreCal.ChainHier

	Insert Into PreCal.ChainHier(NationalChainID, NationalChainName, RegionalChainID, RegionalChainName, LocalChainID, LocalChainName)
	Select NationalChainID, NationalChainName, RegionalChainID, RegionalChainName, LocalChainID, LocalChainName
	From MView.ChainHier v

	-----
	Truncate Table Precal.PromotionLocalChain

	Insert Into Precal.PromotionLocalChain(PromotionID, LocalChainID, PromotionStartDate, PromotionEndDate, IsPromotion)
	Select p.PromotionID, LocalChainID, rp.PromotionStartDate, rp.PromotionEndDate, Case When rp.InformationCategory = 'Promotion' Then 1 Else 0 End
	From Playbook.PromotionAccount p With (nolock)
	Join Playbook.RetailPromotion rp on p.PromotionID = rp.PromotionID
	Where Coalesce(LocalChainID, 0) > 0
	Union
	Select pa.PromotionID, lc.LocalChainID, PromotionStartDate, PromotionEndDate, Case When InformationCategory = 'Promotion' Then 1 Else 0 End
	From Playbook.PromotionAccount pa With (nolock)
	Join SAP.LocalChain lc on(pa.RegionalChainID = lc.RegionalChainID) 
	Join Playbook.RetailPromotion rp on pa.PromotionID = rp.PromotionID
	Where Coalesce(pa.RegionalChainID, 0) > 0
	Union
	Select pa.PromotionID, rc.LocalChainID, PromotionStartDate, PromotionEndDate, Case When InformationCategory = 'Promotion' Then 1 Else 0 End
	From Playbook.PromotionAccount pa With (nolock)
	Join PreCal.ChainHier rc on pa.NationalChainID = rc.NationalChainID
	Join Playbook.RetailPromotion rp on pa.PromotionID = rp.PromotionID
	And Coalesce(pa.NationalChainID, 0) > 0

	-----
	Merge Playbook.ChainGroup cg
	Using (
		Select ChainID, Count(*) Cnt, Min(Chain) Chain, Min(ImageName) ImageName
		From (
			Select Distinct RevRollupChainTypeID as ChainID, RevRollupChainName as Chain, RevImageName as ImageName
			From MSTR.DimChainHier) temp
		Group by ChainID) input
		On input.ChainID = cg.ChainGroupID
	When Not Matched By Target Then
		Insert (ChainGroupID, ChainGroupName, ImageName, WebImageURL, MobileImageURL, Active, CreatedDate, CreateBy, ModifiedDate, ModifiedBy)
		Values (input.ChainID, input.Chain, input.ImageName, 
		'https://dpsg-aws.cloud.microstrategy.com/MicroStrategyMobile/images/DPSG/Amplify%20MyScores/' + ImageName,
		'https://dpsg-aws.cloud.microstrategy.com/MicroStrategyMobile/images/DPSG/Amplify%20MyScores/Mobile/' + ImageName,
		1, GetDate(), 'System', GetDate(), 'System')
	When Not Matched By Source And (ChainGroupID <> 'U00000') Then
		Update
		Set Active = 0, ModifiedDate = GetDate(), ModifiedBy = 'System'
	When Matched And (Active = 0 Or cg.ChainGroupName <> input.Chain Or cg.ImageName <> input.ImageName) Then
		Update
		Set Active = 1, ModifiedDate = GetDate(), ModifiedBy = 'System',
		ChainGroupName = input.Chain,
		ImageName = input.ImageName,
		WebImageURL = 'https://dpsg-aws.cloud.microstrategy.com/MicroStrategyMobile/images/DPSG/Amplify%20MyScores/' + input.ImageName,
		MobileImageURL = 'https://dpsg-aws.cloud.microstrategy.com/MicroStrategyMobile/images/DPSG/Amplify%20MyScores/Mobile/' + input.ImageName;

	Update Playbook.ChainGroup
	Set IsAllOther = 0, CoveredByNational = 0, TrueRegional = 0;

	Update cg
	Set IsAllOther = Case When s.NationalChainID = 62 And s.RegionalChainID = 242 Then 1 Else 0 End,
		TrueRegional = Case When s.NationalChainID = 62 And s.RegionalChainID <> 242 Then 1 Else 0 End,
		CoveredByNational = Case When s.NationalChainID <> 62 Then 1 Else 0 End
	From Playbook.ChainGroup cg
	Join (Select Distinct LocalChainID, RevRollupChainTypeID ChainGroupID From MSTR.DimChainHier Where RevRollupChainTypeID like 'L%') l on cg.ChainGroupID = l.ChainGroupID
	Join PreCal.ChainHier s on l.LocalChainID = s.LocalChainID;

	Update cg
	Set 
		TrueRegional = Case When s.NationalChainID = 62 Then 1 Else 0 End,
		CoveredByNational = Case When s.NationalChainID <> 62 Then 1 Else 0 End
	From Playbook.ChainGroup cg
	Join (Select Distinct RegionalChainID, RevRollupChainTypeID ChainGroupID From MSTR.DimChainHier Where RevRollupChainTypeID like 'R%') l on cg.ChainGroupID = l.ChainGroupID
	Join SAP.RegionalChain s on l.RegionalChainID = s.RegionalChainID;

	Update cg
	Set CoveredByNational = 1
	From Playbook.ChainGroup cg
	Join (Select Distinct NationalChainID, RevRollupChainTypeID ChainGroupID From MSTR.DimChainHier Where RevRollupChainTypeID like 'N%') l on cg.ChainGroupID = l.ChainGroupID;

	--- Expect to See nothing ----
	--Select 'Expect to See nothing'
	--Select ChainGroupID, Sum(Convert(int, TrueRegional) + Convert(int, IsAllOther) + Convert(int, CoveredByNational))
	--From Playbook.ChainGroup cg
	--Group By ChainGroupID
	--Having Sum(Convert(int, TrueRegional) + Convert(int, IsAllOther) + Convert(int, CoveredByNational)) <> 1

	-----
	Truncate Table PreCal.BranchChainGroup

	Insert Into PreCal.BranchChainGroup(BranchID, ChainGroupID)
	Select Distinct a.BranchID, rci.RevRollupChainTypeID as ChainID
	From SAP.Account a,
	MSTR.DimChainHier rci
	Where a.BranchID is not null
	And a.LocalChainID = rci.LocalChainID
	Union
	Select Distinct a.BranchID, b.ChainID
	From
	(
		Select Distinct a.BranchID, ch.RegionalChainID
		From SAP.Account a,
		PreCal.ChainHier ch
		Where a.BranchID is not null
		And a.LocalChainID = ch.LocalChainID
	) a,
	(
		Select Distinct RegionalChainID, RevRollupChainTypeID as ChainID, RevRollupChainName as Chain
		From MSTR.DimChainHier
		Where RevRollupChainTypeID Like 'R%'
	) b
	Where a.RegionalChainID = b.RegionalChainID
	Union
	Select Distinct a.BranchID, b.ChainID
	From
	(
		Select Distinct a.BranchID, ch.NationalChainID
		From SAP.Account a,
		PreCal.ChainHier ch
		Where a.BranchID is not null
		And a.LocalChainID = ch.LocalChainID
	) a,
	(
		Select Distinct NationalChainID, RevRollupChainTypeID as ChainID, RevRollupChainName as Chain
		From MSTR.DimChainHier
		Where RevRollupChainTypeID Like 'N%'
	) b
	Where a.NationalChainID = b.NationalChainID

	-----
	Truncate Table PreCal.PromotionChainGroup;

	With PromotionRegionalChain As
	(
		Select pa.PromotionID, pa.RegionalChainID
		From Playbook.PromotionAccount pa With (nolock)
		Where Coalesce(pa.RegionalChainID, 0) > 0
		Union
		Select Distinct pa.PromotionID, rc.RegionalChainID
		From Playbook.PromotionAccount pa With (nolock)
		Join PreCal.ChainHier rc on pa.NationalChainID = rc.NationalChainID
		Join Playbook.RetailPromotion rp on pa.PromotionID = rp.PromotionID
		And Coalesce(pa.NationalChainID, 0) > 0
	)

	Insert PreCal.PromotionChainGroup(PromotionID, ChainGroupID)
	Select Distinct PromotionID, RevRollupChainTypeID as ChainID
	From PreCal.PromotionLocalChain plc
	Join MSTR.DimChainHier rci on (plc.LocalChainID = rci.LocalChainID)
	Union
	Select Distinct PromotionID, RevRollupChainTypeID as ChainID
	From PromotionRegionalChain plc
	Join MSTR.DimChainHier rci on (plc.RegionalChainID = rci.RegionalChainID And rci.RevRollupChainTypeID Like 'R%')
	Union
	Select Distinct PromotionID, RevRollupChainTypeID as ChainID
	From PlayBook.PromotionAccount pa
	Join PreCal.ChainHier ch on pa.LocalChainID = ch.LocalChainID
	Join MSTR.DimChainHier rci on (ch.NationalChainID = rci.NationalChainID And rci.RevRollupChainTypeID Like 'N%');

	---
	Truncate Table PreCal.RegionTMLocalChain;

	Insert PreCal.RegionTMLocalChain(RegionID, TradeMarkID, LocalChainID)
	Select Distinct RegionID, TradeMarkID, LocalChainID
	From BC.tRegionChainTradeMark tmap
	Where tmap.TerritoryTypeID <> 10
	And tmap.ProductTypeID = 1;

	---
	-----------------------------
	Merge PreCal.CustomBrandPackageCategory As tar
	Using (Select [SDMCategoryID], [CategoryDescription], [IsTrademarkFlag], cpc.[TradeMarkID], PackageID, PackageName,
		cpc.BrandID, [TradeMarkName], [BrandName] 
		From Mview.CustomBrandPackageCategory cpc 
		Left Join SAP.Trademark t on cpc.TradeMarkID = t.TradeMarkID 
		Left Join SAP.Brand b on cpc.BrandID = b.BrandID)
		as input
	On tar.SDMCategoryID = input.SDMCategoryID 
		And tar.PackageID = input.PackageID
		And tar.TrademarkId = input.TrademarkID
		And isnull(tar.BrandID, -1) = isnull(input.BrandID, -1)
	When Matched Then
		Update Set tar.CategoryDescription = input.CategoryDescription,
				   tar.PackageName = input.PackageName,
				   tar.IsTradeMarkFlag = input.IsTradeMarkFlag,
				   tar.BrandName = input.BrandName,
				   tar.TradeMarkName = input.TradeMarkName
	When Not Matched By Target Then
		Insert (SDMCategoryID, CategoryDescription, PackageID, PackageName, IsTradeMarkFlag, TradeMarkID, BrandID, BrandName, TradeMarkName)
		Values (input.SDMCategoryID, input.CategoryDescription, input.PackageID, input.PackageName, input.IsTradeMarkFlag, input.TradeMarkID, input.BrandID, input.BrandName, input.TradeMarkName)
	When NOT MATCHED By Source THEN
		Delete;

End





GO

