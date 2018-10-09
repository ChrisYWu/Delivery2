Use Portal_Data
Go

If Exists (Select *
			From sys.tables t
			Join sys.schemas s on t.schema_id = s.schema_id
			Where t.Name = 'PromotionChannel'
			And s.Name = 'PreCal')
Begin
	Drop Table [PreCal].[PromotionChannel]
End
Go

-------------------------------
CREATE TABLE [PreCal].[PromotionChannel](
	[PromotionID] [int] NOT NULL,
	[ChannelID] [int] NOT NULL,
	CONSTRAINT [PK_PromotionChannel] PRIMARY KEY CLUSTERED 
(
	[PromotionID] ASC,
	[ChannelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
Go

----- Inital Load
Truncate Table PreCal.PromotionChannel
Go

Insert PreCal.PromotionChannel
Select Distinct PromotionID, c.ChannelID
From Playbook.PromotionChannel pc
Join SAP.Channel c on pc.SuperChannelID = c.SuperChannelID
Union
Select PromotionID, ChannelID
From Playbook.PromotionChannel pc
Where ChannelID is not null
Go

---------------------------------------------
---------------------------------------------
---------------------------------------------
/****** Object:  StoredProcedure [PreCal].[pRefreshLookups]    Script Date: 3/8/2017 11:23:42 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
exec PreCal.pRefreshLookups
*/


ALTER Proc [PreCal].[pRefreshLookups]
As
Begin
	Set NoCount On

	-----
	Truncate Table PreCal.PromotionChannel

	Insert PreCal.PromotionChannel
	Select Distinct PromotionID, c.ChannelID
	From Playbook.PromotionChannel pc
	Join SAP.Channel c on pc.SuperChannelID = c.SuperChannelID
	Union
	Select PromotionID, ChannelID
	From Playbook.PromotionChannel pc
	Where ChannelID is not null

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
	From MView.ActiveChainHier v

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
		'https://dpsg.cloud.microstrategy.com/MicroStrategy/images/DPSG/Amplify%20MyScores/' + ImageName,
		'https://dpsg.cloud.microstrategy.com/MicroStrategy/images/DPSG/Amplify%20MyScores/Mobile/' + ImageName,
		1, GetDate(), 'System', GetDate(), 'System')
	When Not Matched By Source And (ChainGroupID <> 'U00000') Then
		Update
		Set Active = 0, ModifiedDate = GetDate(), ModifiedBy = 'System'
	When Matched And (Active = 0 Or cg.ChainGroupName <> input.Chain Or cg.ImageName <> input.ImageName) Then
		Update
		Set Active = 1, ModifiedDate = GetDate(), ModifiedBy = 'System',
		ChainGroupName = input.Chain,
		ImageName = input.ImageName,
		WebImageURL = 'https://dpsg.cloud.microstrategy.com/MicroStrategy/images/DPSG/Amplify%20MyScores/' + input.ImageName,
		MobileImageURL = 'https://dpsg.cloud.microstrategy.com/MicroStrategy/images/DPSG/Amplify%20MyScores/Mobile/' + input.ImageName;

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

---------------------------------------------
---------------------------------------------
---------------------------------------------


----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('[Playbook].[pGetPromotionsByRouteID]'))
Begin
	Drop Proc [Playbook].[pGetPromotionsByRouteID]
	Print '* [Playbook].[pGetPromotionsByRouteID]'
End
Go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*
EXEC [Playbook].[pGetPromotionsByRouteID] @RouteNumber = 113301150

-- Validation as of 20170310
--1:Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502107
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502107

--2:Q:0/0|P:7/7
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502117
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502117

--3:Q:10/10|P:300/300
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 113301150
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 113301150

--EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 113301150, @Debug = 1

--4:Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 109400120
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 109400120

--5:Q:0/0|P:5/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581913
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581913

--6:Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 112501008
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 112501008

--7:Q:8/8|P:93/93
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 102000049
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 102000049

EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 102000049, @Debug = 1

--8:Q:8/8|P:104/104
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581025
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581025

111502107          107 IRVING BULK SALES
111502117          117 IRVING TELEPHONE SALES
113301150          150 SAN LEANDRO COMBO SALES
109400120          120 CLEVELAND COMBO SALES
100581913          81913 MIAMI SALES
112501008          008 LOS ANGELES COMBO SALES
102000049          049 CHICAGO SALES AM
100581025 

*/

CREATE PROCEDURE [Playbook].[pGetPromotionsByRouteID] 
(
	@RouteNumber  VARCHAR(30),
	@lastmodified DATETIME    = NULL,
	@Debug bit = 0
)
AS
    Begin
		Set NoCount On;
		If (@Debug = 1)
		Begin
			Declare @StartTime DateTime2(7)
			Set @StartTime = SysDateTime()
			Select @StartTime StartTime
		End

		Declare @RouteID Int, @ConfigPStartDate DateTime, @ConfigPEndDate DateTime

		Select @RouteID = RouteID
		From SAP.Route WITH (NOLOCK)
		Where SAPRouteNumber = @RouteNumber

		Select @ConfigPStartDate = DATEADD(DAY,
									(
										SELECT CONVERT( INT, value * -1)
										FROM BCMyDay.Config WITH (NOLOCK)
										WHERE [Key] = 'DSD_PROMOTION_DOWNLOAD_DURATION_PAST'
									), DAteAdd(Day, -1, GetDate()));

		Select @ConfigPEndDate = DATEADD(DAY,
									(
										SELECT CONVERT( INT, value)
										FROM BCMyDay.Config WITH (NOLOCK)
										WHERE [Key] = 'DSD_PROMOTION_DOWNLOAD_DURATION_FUTURE'
									), GetDate());

		------------------------------
		Declare @RouteIDs Table
		(
			RouteID int Not Null Primary Key
		)

		Insert Into @RouteIDs Values (@RouteID)
		Insert Into @RouteIDs
		Select RouteID
		From SAP.Route
		Where SalesGroup IN
		(
			Select SalesGroup
			From SAP.Route
			Where RouteID = @RouteID
			And DISPLAYAllowance = 1
			And SalesGroup NOT IN
			(
				SELECT SalesGroupID
				FROM SAP.RouteSalesGroupExclusion WITH (NOLOCK)
			)
			And IsNull(Active, 0) = 1
		)
		And IsNull(Active, 0) = 1

		If @Debug = 1
		Begin
			Select '--Routes--' Debug
			Select *
			From @RouteIDs

			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_RouteIDS

		End

		---------------------------------------
		Declare @BLC Table
		(
			BranchID int,
			LocalChainID int,
			ChannelID int
		)

		Insert Into @BLC
		Select Distinct BranchID, LocalChainID, ChannelID
		From @RouteIDs rt
		Join SAP.RouteSchedule rs on rt.RouteID = rs.RouteID
		Join SAP.Account a on rs.AccountID = a.AccountID
		--Where a.Active = 1

		---------------------------------------
		Declare @BLCA Table
		(
			BranchID int,
			LocalChainID int,
			ChannelID int,
			AccountID int,
			SAPAccountNumber bigint not null,
			Active bit
		)

		Insert Into @BLCA
		Select Distinct BranchID, LocalChainID, ChannelID, a.AccountID, SAPAccountNumber, a.Active
		From @RouteIDs rt
		Join SAP.RouteSchedule rs on rt.RouteID = rs.RouteID
		Join SAP.Account a on rs.AccountID = a.AccountID

		If @Debug = 1
		Begin
			Select '--BLC--' Debug
			Select *
			From @BLC

			Select '--BLCA--' Debug
			Select *
			From @BLCA

			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_RouteToChainChannelAccountMapping

		End
		---------------------------------------

		Declare @PromotionIDs Table
		(
			PromotionID int,
			LocalChainID int,
			ChannelID int,
			PromotionGroupID int
		)

		Insert Into @PromotionIDs
		------- Chain Promotion
		Select Distinct pb.PromotionID, pcl.LocalChainID, null ChannelID, rb.PromotionGroupID
		From PreCal.PromotionBranch pb
		Join @BLC r on pb.BranchID = r.BranchID
		Join PreCal.PromotionLocalChain pcl on pcl.PromotionID = pb.PromotionID And r.LocalChainID = pcl.LocalChainID
		Join Playbook.RetailPromotion rb on pb.PromotionID = rb.PromotionID
		Where pb.PromotionStartDate < @ConfigPEndDate
		And pb.PromotionEndDate > @ConfigPStartDate
		And PromotionStatusID = 4
		Union
		------- Channel Promotions
		Select Distinct pb.PromotionID, null, pc.ChannelID, rb.PromotionGroupID
		From PreCal.PromotionBranch pb
		Join @BLC r on pb.BranchID = r.BranchID
		Join PreCal.PromotionChannel pc On r.ChannelID = pc.ChannelID And pb.PromotionID = pc.PromotionID
		Join Playbook.RetailPromotion rb on pb.PromotionID = rb.PromotionID
		Where pb.PromotionStartDate < @ConfigPEndDate
		And pb.PromotionEndDate > @ConfigPStartDate
		And PromotionStatusID = 4

		------------------------------
		If @Debug = 1
		Begin
			Select '--Promotions--' Debug
			Select *
			From @PromotionIDs
		
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonID

		End

		---------------------------------------------------------
		---------------------------------------------------------
		---------------------------------------------------------
		---------------------------------------------------------

		-- Result #1 Promotion details
		SELECT DISTINCT
			rp.PromotionID 'PromotionID',
			PromotionName 'PromotionName',
			ISNULL(PromotionDescription, '') 'PromotionDescription',
			[BCMyday].[fGetUTCDate](PromotionStartDate) 'InStoreStartDate',
			[BCMyday].[fGetUTCDate](PromotionEndDate) 'InStoreEndDate',
			[BCMyday].[fGetUTCDate](DisplayStartDate) 'DisplayStartDate',
			[BCMyday].[fGetUTCDate](DisplayEndDate) 'DisplayEndDate',
			[BCMyday].[fGetUTCDate](PricingStartDate) 'PricingStartDate',
			[BCMyday].[fGetUTCDate](PricingEndDate) 'PricingEndDate',
			ISNULL(ForecastVolume, '') 'ForecastedVolume',
			ISNULL(NationalDisplayTarget, '') 'NationalDisplayTarget',
			ISNULL(PromotionPrice, '') 'RetailPrice',
			ISNULL(BottlerCommitment, '') 'InvoicePrice',
			ISNULL(pc.promotioncategoryname, '') 'Category',
			rp.PromotionCategoryID 'CategoryID'		,

			CASE pdl.DisplayRequirement
				WHEN '1'
				THEN 'Mandatory'
				WHEN '2'
				THEN 'Local Sell-In'
				ELSE 'No Display'
			END AS 'DisplayRequirement',
			ISNULL(DisplayLocationID, 0) 'DisplayLocationID',
			ISNULL(DisplayTypeID, 0) 'DisplayTypeID',
			ISNULL(PromotionType, '') 'PromotionType',
			ISNULL(pdl.PromotionDisplayLocationOther, '') 'DisplayComments',
			0 'DisplayRequired',
			0 [Priority]		,

			CASE
				WHEN(rp.promotionstatusid = 4)
				THEN 1
				ELSE 0
			END AS 'IsActive',
			CASE
				WHEN(rp.promotionstatusid = 4)
				THEN 0
				ELSE 1
			END AS 'IsDeleted',
			InformationCategory,
			ISNULL(OtherBrandPriced, '') 'BrandComments',
			ISNULL(SendBottlerAnnouncement, 0) 'SendBottlerAnnouncement',
			rp.PromotionGroupID 'PromotionGroupID'
		FROM playbook.retailpromotion rp WITH (NOLOCK)
			LEFT JOIN playbook.promotiontype pt WITH (NOLOCK) ON rp.Promotiontypeid = pt.promotiontypeid
			INNER JOIN playbook.promotioncategory pc WITH (NOLOCK) ON rp.promotioncategoryid = pc.promotioncategoryid
			INNER JOIN playbook.promotiondisplaylocation pdl WITH (NOLOCK) ON rp.promotionid = pdl.promotionid
		WHERE rp.PromotionID IN
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);

		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonDetails
		End

		-- Result #2 Promotion Brand Trademark details
		SELECT PromotionID 'PromotionID',
			ISNULL(a.BrandID, 0) 'BrandID',
			CASE
				WHEN ISNULL(a.TrademarkID, 0) = 0
				THEN ISNULL(b.trademarkid, 0)
				ELSE ISNULL(a.TrademarkID, 0)
			END 'TrademarkID'
		FROM playbook.promotionbrand a WITH (NOLOCK)
			LEFT JOIN sap.brand b WITH (NOLOCK) ON a.brandid = b.brandid
		Where PromotionID In
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);

		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonBrands
		End

		-- Result #3 Promotion chain details 
		SELECT PromotionID 'PromotionID',
			CASE
				WHEN ISNULL(a.RegionalChainID, 0) <> 0
				THEN
		(
			SELECT snc.SAPnationalchainid
			FROM sap.regionalchain WITH (NOLOCK)
				LEFT JOIN sap.nationalchain snc WITH (NOLOCK) ON snc.nationalchainid = regionalchain.nationalchainid
			WHERE regionalchain.RegionalChainID = a.RegionalChainID
		)
				WHEN ISNULL(a.LocalChainID, 0) <> 0
				THEN
		(
			SELECT snc.sapnationalchainid
			FROM sap.localchain b WITH (NOLOCK)
				LEFT JOIN sap.regionalchain c WITH (NOLOCK) ON b.regionalchainid = c.regionalchainid
				LEFT JOIN sap.nationalchain snc WITH (NOLOCK) ON snc.nationalchainid = c.nationalchainid
			WHERE b.localchainid = a.localchainid
		)
				ELSE ISNULL(nc.SAPnationalchainid, 0)
			END 'NationalChainID',
			CASE
				WHEN ISNULL(a.LocalChainID, 0) <> 0
				THEN
		(
			SELECT src.SAPregionalchainid
			FROM sap.localchain WITH (NOLOCK)
				LEFT JOIN sap.regionalchain src WITH (NOLOCK) ON localchain.regionalchainid = src.regionalchainid
			WHERE localchainid = a.localchainid
		)
				ELSE ISNULL(rc.SAPRegionalChainID, 0)
			END 'RegionalChainID',
			ISNULL(lc.SAPLocalChainID, 0) 'LocalChainID'
		FROM playbook.promotionaccount a WITH (NOLOCK)
			LEFT JOIN sap.nationalchain nc WITH (NOLOCK) ON nc.nationalchainid = a.nationalchainid
			LEFT JOIN sap.regionalchain rc WITH (NOLOCK) ON rc.regionalchainid = a.regionalchainid
			LEFT JOIN sap.localchain lc WITH (NOLOCK) ON lc.localchainid = a.localchainid
		Where PromotionID In
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);
	
		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonAccounts
		End

		--Result #4 Promotion Attachments details 
		SELECT PromotionID 'PromotionID',
			AttachmentURL 'FileURL',
			AttachmentName 'FileName',
			ISNULL(AttachmentSize, 0) 'Size',
			at.AttachmentTypeName 'Type',
			pa.PromotionAttachmentID 'AttachmentID',
			[BCMyday].[fGetUTCDate](pa.AttachmentDateModified) 'LastModifiedDate'
		FROM playbook.promotionattachment pa WITH (NOLOCK)
			INNER JOIN Playbook.AttachmentType at WITH (NOLOCK) ON pa.AttachmentTypeID = at.AttachmentTypeID
		Where PromotionID In
		(
			SELECT PromotionID
			FROM @PromotionIDs
		)
		AND at.AttachmentTypeName <> 'Fin Admin';
	
		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonActtachments
		End

		--Result #5 Promotion package details 
		SELECT PromotionID 'PromotionID',
			PackageID
		FROM playbook.promotionpackage pa WITH (NOLOCK)
		Where PromotionID In
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);

		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonPackages
		End

		----Result #6 Promotion priority details 
		SELECT PromotionID 'PromotionID',
			FORMAT(PromotionWeekStart, 'MM-dd-yyyy') 'WeekStartDate',
			FORMAT(PromotionWeekEnd, 'MM-dd-yyyy') 'WeekEndDate',
			ISNULL([Rank], 0) AS 'Priority',
			pa.ChainGroupID
		FROM playbook.promotionRank pa WITH (NOLOCK)
		Where PromotionID In
		(
			SELECT PromotionID
			FROM @PromotionIDs
		)
		AND ISNULL(Rank, 0) <> 0
		AND ISNULL(Rank, 0) <> 100;
		
		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonPriority
		End
		
		---- Result #7 Promotion customer details  
		--Getting promotions/account mapping for those account only which are in this routes)
		Select Distinct p.PromotionID, r.AccountID, r.SAPAccountNumber CustomerNumber 
		From @PromotionIDs p
		Join @BLCA r on p.LocalChainID = r.LocalChainID
		Where p.PromotionGroupID = 1
		Union
		Select Distinct p.PromotionID, r.AccountID, r.SAPAccountNumber CustomerNumber 
		From @PromotionIDs p
		Join @BLCA r on p.ChannelID = r.ChannelID
		Where p.PromotionGroupID = 2

		If @Debug = 1
		Begin
			Select DateDiff(millisecond, @StartTime, SysDateTime()) OnGoingMilliSec_PromoitonCustomer
		End

	END;
GO

Print '[Playbook].[pGetPromotionsByRouteID]'
Go


--------------------------------------------
--------------------------------------------
--------------------------------------------
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




