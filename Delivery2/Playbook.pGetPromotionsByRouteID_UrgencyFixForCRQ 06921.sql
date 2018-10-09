USE [Portal_Data]
GO

------------------------------------------------------------------
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
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 111502107

--2:Q:0/0|P:7/7
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502117
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 111502117

--3:Q:10/10|P:300/300
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 113301150
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 113301150

--EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 113301150, @Debug = 1

--4:Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 109400120
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 109400120

--5:Q:0/0|P:5/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581913
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 100581913

--6:Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 112501008
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 112501008

--7:Q:8/8|P:93/93
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 102000049
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 102000049

EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 102000049, @Debug = 1

--8:Q:8/8|P:104/104
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581025
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 100581025

111502107          107 IRVING BULK SALES
111502117          117 IRVING TELEPHONE SALES
113301150          150 SAN LEANDRO COMBO SALES
109400120          120 CLEVELAND COMBO SALES
100581913          81913 MIAMI SALES
112501008          008 LOS ANGELES COMBO SALES
102000049          049 CHICAGO SALES AM
100581025 

EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 103900170

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
		And RouteID <> @RouteID

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

