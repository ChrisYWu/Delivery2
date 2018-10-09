USE [Portal_Data]
GO

----------------------------------------------------------------
If Exists (Select * From sys.objects Where object_Id = object_Id('[Playbook].[pGetPromotionsByRouteIDWu]'))
Begin
	Drop Proc [Playbook].[pGetPromotionsByRouteIDWu]
	Print '* [Playbook].[pGetPromotionsByRouteIDWu]'
End
Go

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/*

Select *
From SAP.Route
Where RouteTypeID = 0
And RouteName like '%San Leandro%'
Order By SAPRouteNumber


EXEC [Playbook].[pGetPromotionsByRouteID] @RouteNumber = 113301150
EXEC [Playbook].[pGetPromotionsByRouteIDWu] @RouteNumber = 113301150


EXEC [Playbook].[pGetPromotionsByRouteID] @RouteNumber = 113301080
EXEC [Playbook].[pGetPromotionsByRouteIDWu] @RouteNumber = 113301080

-- Validation as of 20170308
--Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502107
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 111502107

--Q:0/0|P:6/6
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 111502117
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 111502117

--Q:10/10|P:297/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 113301150
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 113301150


--Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 109400120
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 109400120

--Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 100581913
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 100581913

--Q:0/0|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 112501008
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 112501008

--Q:8/8|P:0/0
EXEC Playbook.pGetPromotionsByRouteID @RouteNumber = 102000049
EXEC Playbook.pGetPromotionsByRouteIDWu @RouteNumber = 102000049



111502107          107 IRVING BULK SALES
111502117          117 IRVING TELEPHONE SALES
113301150          150 SAN LEANDRO COMBO SALES
109400120          120 CLEVELAND COMBO SALES
100581913          81913 MIAMI SALES
112501008          008 LOS ANGELES COMBO SALES
102000049          049 CHICAGO SALES AM

*/

CREATE PROCEDURE [Playbook].[pGetPromotionsByRouteIDWu] @RouteNumber  VARCHAR(30),
                                                      @lastmodified DATETIME    = NULL
AS
    Begin
		Set NoCount On;
		Declare @RouteID Int, @ConfigPStartDate DateTime, @ConfigPEndDate DateTime, @Debug bit = 1

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
			RouteID int
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
		End

		---------------------------------------
		Declare @BLC Table
		(
			BranchID int,
			LocalChainID int,
			ChannelID int
		)

		Insert Into @BLC
		Select Distinct r.BranchID, LocalChainID, ChannelID
		From SAP.Route r
		Join @RouteIDs rt on r.RouteID = rt.RouteID
		Join SAP.RouteSchedule rs on r.RouteID = rs.RouteID
		Join SAP.Account a on rs.AccountID = a.AccountID

		If @Debug = 1
		Begin
			Select '--Routes--' Debug
			Select *
			From @BLC
		End
		---------------------------------------

		Declare @PromotionIDs Table
		(
			PromotionID int
		)

		Insert Into @PromotionIDs
		------- Chain Promotion
		--Select Distinct pb.PromotionID
		--From PreCal.PromotionBranch pb
		--Join @BLC r on pb.BranchID = r.BranchID
		--Join PreCal.PromotionLocalChain pcl on pcl.PromotionID = pb.PromotionID And r.LocalChainID = pcl.LocalChainID
		--Join Playbook.RetailPromotion rb on pb.PromotionID = rb.PromotionID
		--Where pb.PromotionStartDate < @ConfigPEndDate
		--And pb.PromotionEndDate > @ConfigPStartDate
		--And PromotionStatusID = 4
		--Union
		------- Channel Promotions
		Select Distinct pb.PromotionID
		From PreCal.PromotionBranch pb
		Join @BLC r on pb.BranchID = r.BranchID
		Join PreCal.BranchChannel bc On bc.BranchID = pb.BranchID And bc.ChannelID = r.ChannelID
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
		WHERE promotionid IN
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);

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
		WHERE promotionid IN
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);

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
		WHERE promotionid IN
		(
			SELECT PromotionID
			FROM @PromotionIDs
		)
			AND at.AttachmentTypeName <> 'Fin Admin';
	
		--Result #5 Promotion package details 
		SELECT PromotionID 'PromotionID',
			PackageID
		FROM playbook.promotionpackage pa WITH (NOLOCK)
		WHERE promotionid IN
		(
			SELECT PromotionID
			FROM @PromotionIDs
		);

		--Result #6 Promotion priority details 
		SELECT PromotionID 'PromotionID',
			FORMAT(PromotionWeekStart, 'MM-dd-yyyy') 'WeekStartDate',
			FORMAT(PromotionWeekEnd, 'MM-dd-yyyy') 'WeekEndDate',
			ISNULL([Rank], 0) AS 'Priority',
			pa.ChainGroupID
		FROM playbook.promotionRank pa WITH (NOLOCK)
		WHERE promotionid IN
		(
			SELECT PromotionID
			FROM @PromotionIDs
		)
			AND ISNULL(Rank, 0) <> 0
			AND ISNULL(Rank, 0) <> 100;
		
		-- Result #7 Promotion customer details 
		SELECT DISTINCT
			a.promotionid PromotionID,
			c.accountid AccountID,
			--CONVERT( VARCHAR(10), SAPAccountNumber) AS 'CustomerNumber'
			SAPAccountNumber AS 'CustomerNumber'
		FROM @PromotionIDs a
			LEFT JOIN playbook.retailpromotion rp WITH (NOLOCK) ON a.promotionid = rp.promotionid
			LEFT JOIN [PreCal].[PromotionLocalChain] b WITH (NOLOCK) ON a.promotionid = b.promotionid
			LEFT JOIN sap.account c WITH (NOLOCK) ON c.localchainid = b.localchainid
		WHERE rp.PromotionGroupID = 1 --Account based promotion
			AND c.accountid IN
		(
			SELECT rsch.AccountID
			FROM sap.RouteSchedule rsch WITH (NOLOCK)
			WHERE rsch.routeid IN
			(
				SELECT routeid
				FROM @RouteIDs
			)
		)  --Getting promotions/account mapping for those account only which are in this routes)

		UNION
		SELECT DISTINCT
			a.promotionid,
			c.accountid,
			--CONVERT( VARCHAR(10), SAPAccountNumber) AS 'CustomerNumber'
			SAPAccountNumber AS 'CustomerNumber'
		FROM @PromotionIDs a
			LEFT JOIN playbook.retailpromotion rp WITH (NOLOCK) ON a.promotionid = rp.promotionid
			LEFT JOIN playbook.promotionchannel b WITH (NOLOCK) ON a.promotionid = b.promotionid
			LEFT JOIN sap.channel chl WITH (NOLOCK) ON b.SuperChannelID = chl.SuperChannelID
			LEFT JOIN sap.account c WITH (NOLOCK) ON(c.channelid = CASE
																		WHEN ISNULL(b.channelid, 0) = 0
																		THEN chl.channelid
																		ELSE b.channelId
																	END)
		WHERE rp.PromotionGroupID = 2 --Channel based promotion
			AND c.accountid IN
		(
			SELECT rsch.AccountID
			FROM sap.RouteSchedule rsch WITH (NOLOCK)
			WHERE rsch.routeid IN
			(
				SELECT routeid
				FROM @RouteIDs
			)
		);  --Getting promotions/account mapping for those account only which are in this routes)
	END;
GO

Print '[Playbook].[pGetPromotionsByRouteIDWu]'
Go

