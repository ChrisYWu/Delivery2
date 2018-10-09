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

-----------------------------
-----------------------------
-----------------------------


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

-----------------------------
-----------------------------
-----------------------------

/****** Object:  StoredProcedure [Playbook].[pGetPromotionsByRouteID]    Script Date: 3/10/2017 11:31:49 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
  EXEC [Playbook].[pGetPromotionsByRouteID] @RouteNumber = 113301150
*/
ALTER PROCEDURE [Playbook].[pGetPromotionsByRouteID] @RouteNumber  VARCHAR(30),
                                                      @lastmodified DATETIME    = NULL
AS
     BEGIN
         SET NOCOUNT ON;
	    DECLARE @NoDeltaDownload BIT,  @RouteID INT, @ConfigPStartDate DATETIME, @ConfigPEndDate DATETIME, @BranchID VARCHAR(20), @isValid BIT
	    DECLARE @LOCAL_RouteNumber VARCHAR(30), @LOCAL_lastModified DATETIME

         IF OBJECT_ID('tempdb..#Promotions') IS NOT NULL
             DROP TABLE #Promotions;
         IF OBJECT_ID('tempdb..#ValidPromotions') IS NOT NULL
             DROP TABLE #ValidPromotions;
         IF OBJECT_ID('tempdb..#PromotionStatus') IS NOT NULL
             DROP TABLE #PromotionStatus;
         IF OBJECT_ID('tempdb..#IORoute') IS NOT NULL
             DROP TABLE #IORoute;

	    -- disable param sniffing
	    SET @LOCAL_RouteNumber = @RouteNumber;
	    SET @LOCAL_lastModified = @lastmodified;

	    SET @isValid = TRY_CONVERT(INT, @LOCAL_RouteNumber);
	    IF(COALESCE(@isValid, 0) = 0) THROW 51000, 'Parameter @RouteNumber failed test for being an integer. Provided a valid value', 1;

	    CREATE TABLE #PromotionStatus (value INT)
	    CREATE TABLE #IORoute (RouteID INT)
	    CREATE TABLE #Promotions(PromotionID INT)
	    CREATE TABLE #ValidPromotions(PromotionID INT)

	    CREATE NONCLUSTERED INDEX IDX1 ON #PromotionStatus(value)
	    CREATE NONCLUSTERED INDEX IDX2 ON #IORoute(RouteID)
	    CREATE NONCLUSTERED INDEX IDX3 ON #Promotions(PromotionID)
	    CREATE NONCLUSTERED INDEX IDX4 ON #ValidPromotions(PromotionID)

	    SELECT @RouteID = RouteID
            FROM [SAP].[ROUTE] WITH (NOLOCK)
            WHERE SAPRouteNumber = @LOCAL_RouteNumber;
	    
	    INSERT INTO #PromotionStatus(value)VALUES(4)
         --SELECT 4 value INTO #PromotionStatus;

         --IO Routes
	    INSERT INTO #IORoute(RouteID)VALUES(-1)
         --SELECT-1 RouteID INTO #IORoute

	    IF ISDATE(@LOCAL_lastModified) = 1 -- 1 equals valid date
	    BEGIN
		  INSERT INTO #PromotionStatus(value) VALUES(3);	--Cancel promotion also required for delta
	    END
         
         SELECT @NoDeltaDownload = CONVERT( BIT, ISNULL(value, 0))
         FROM [BCMYDAY].[Config] WITH (NOLOCK)
         WHERE [key] = 'DSD_PROMOTION_DISABLE_DELTA_DOWNLOAD';

         IF(ISNULL(@NoDeltaDownload, 0) = 1)
	    BEGIN
	        SET @LOCAL_lastModified = NULL;
	    END

         SELECT @ConfigPStartDate = DATEADD(DAY,
                                           (
                                               SELECT CONVERT( INT, value * -1)
                                               FROM [BCMYDAY].[Config] WITH (NOLOCK)
                                               WHERE [key] = 'DSD_PROMOTION_DOWNLOAD_DURATION_PAST'
                                           ), GETDATE());

         SELECT @ConfigPEndDate = DATEADD(DAY,
                                         (
                                             SELECT CONVERT( INT, value)
                                             FROM [BCMYDAY].[Config] WITH (NOLOCK)
                                             WHERE [key] = 'DSD_PROMOTION_DOWNLOAD_DURATION_FUTURE'
                                         ), GETDATE());

	    INSERT INTO #Promotions(PromotionID)VALUES(-1);
	    INSERT INTO #ValidPromotions(PromotionID)VALUES(-1);

         SELECT @BranchId = CONVERT( VARCHAR(20), branchid)
         FROM [SAP].[ROUTE] WITH (NOLOCK)
         WHERE routeid = @RouteID;

         IF EXISTS
         (
             SELECT 1
             FROM [SAP].[Route] RTE WITH (NOLOCK) 
             WHERE DISPLAYAllowance = 1  AND RTE.RouteID = @RouteID AND RTE.SalesGroup NOT IN
             (
                 SELECT SalesGroupId
                 FROM SAP.RouteSalesGroupExclusion WITH (NOLOCK)
             )
         )
             BEGIN
                 --Getting all IO Routes
                 INSERT INTO #IORoute(RouteID)
                        SELECT RouteID
                        FROM [SAP].[Route] WITH (NOLOCK)
                        WHERE SalesGroup IN
                        (
                            SELECT SalesGroup
                            FROM [SAP].[Route] WITH (NOLOCK)
                            WHERE RouteID = @RouteID
                                  AND DISPLAYAllowance = 1
                                  AND SalesGroup NOT IN
                            (
                                SELECT SalesGroupId
                                FROM SAP.RouteSalesGroupExclusion WITH (NOLOCK)
                            )
                                  AND ISNULL(Active, 0) = 1
                        )
                              AND ISNULL(Active, 0) = 1;

                 --getting branches of all off routes
                 SET @BranchId = @BranchId +
                 (
                     SELECT DISTINCT ',' + CONVERT( VARCHAR(20), branchid)
                     FROM [SAP].[Route] WITH (NOLOCK)
                     WHERE RouteID IN
                     (
                         SELECT RouteID FROM #IORoute WITH (NOLOCK)
                     )
                     FOR XML PATH('')
                 );
             END;
         ELSE
             BEGIN
                 INSERT INTO #IORoute(RouteID)VALUES(@RouteID);
             END;		

         --Getting promotions for braches for these routes
         INSERT INTO #Promotions
         EXEC [Playbook].[pGetPromotionsByRole]
              @StartDate = @ConfigPStartDate,
              @EndDate = @ConfigPEndDate,
              @currentuser = '',
              @Branchid = @BranchId,
              @VIEW_DRAFT_NA = 1,
              @ViewNatProm = 1,
              @RolledOutAccounts = '',
              @IsExport = 0,
              @CurrentPersonaID = -1,
              @MyDay = 1;


         INSERT INTO #ValidPromotions
                SELECT DISTINCT
                       a.promotionId
                FROM playbook.retailpromotion a WITH (NOLOCK)
                     LEFT JOIN [PreCal].[PromotionLocalChain] b WITH (NOLOCK) ON a.promotionid = b.promotionid
                WHERE a.ModifiedDate >= CASE
                                            WHEN ISNULL(@LOCAL_lastModified, '') = ''
                                            THEN a.ModifiedDate
                                            ELSE @LOCAL_lastModified
                                        END	--For delta only modifed promotion else all
                      AND a.promotionstatusid IN
                (
                    SELECT value
                    FROM #PromotionStatus WITH (NOLOCK)
                )
                      AND a.promotionid IN
                (
                    SELECT promotionid
                    FROM #Promotions WITH (NOLOCK)
                )
                      AND b.localchainid IN
                (
                    SELECT ac.LocalChainID
                    FROM sap.RouteSchedule rsch WITH (NOLOCK)
                         LEFT JOIN sap.account ac WITH (NOLOCK) ON rsch.accountid = ac.accountid
                    WHERE rsch.routeid IN
                    (
                        SELECT routeid
                        FROM #IORoute WITH (NOLOCK)
                    )
                )  --Getting promotions for those account only which are in this route

                UNION
                SELECT DISTINCT
                       a.promotionId
                FROM playbook.retailpromotion a WITH (NOLOCK)
                     INNER JOIN playbook.promotionchannel b WITH (NOLOCK) ON a.promotionid = b.promotionid
                     LEFT JOIN sap.channel chl WITH (NOLOCK) ON b.SuperChannelID = chl.SuperChannelID
                     LEFT JOIN shared.tlocationchain c WITH (NOLOCK) ON(c.channelid = CASE
                                                                                          WHEN ISNULL(b.channelid, 0) = 0
                                                                                          THEN chl.channelid
                                                                                          ELSE b.channelId
                                                                                      END)
                WHERE a.ModifiedDate >= CASE
                                            WHEN ISNULL(@LOCAL_lastModified, '') = ''
                                            THEN a.ModifiedDate
                                            ELSE @LOCAL_lastModified
                                        END	--For delta only modifed promotion else all
                      AND a.promotionstatusid IN
                (
                    SELECT value
                    FROM #PromotionStatus WITH (NOLOCK)
                )
                      AND a.promotionid IN
                (
                    SELECT promotionid
                    FROM #Promotions WITH (NOLOCK)
                )
                      AND c.localchainid IN
                (
                    SELECT ac.LocalChainID
                    FROM sap.RouteSchedule rsch WITH (NOLOCK)
                         LEFT JOIN sap.account ac WITH (NOLOCK) ON rsch.accountid = ac.accountid
                    WHERE rsch.routeid IN
                    (
                        SELECT routeid
                        FROM #IORoute WITH (NOLOCK)
                    )
                ); 


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
             FROM #ValidPromotions WITH (NOLOCK)
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
             FROM #ValidPromotions WITH (NOLOCK)
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
             FROM #ValidPromotions WITH (NOLOCK)
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
             FROM #ValidPromotions WITH (NOLOCK)
         )
               AND at.AttachmentTypeName <> 'Fin Admin';
	
         --Result #5 Promotion package details 
         SELECT PromotionID 'PromotionID',
                PackageID
         FROM playbook.promotionpackage pa WITH (NOLOCK)
         WHERE promotionid IN
         (
             SELECT PromotionID
             FROM #ValidPromotions WITH (NOLOCK)
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
             FROM #ValidPromotions WITH (NOLOCK)
         )
               AND ISNULL(Rank, 0) <> 0
               AND ISNULL(Rank, 0) <> 100;
		
         -- Result #7 Promotion customer details 
         SELECT DISTINCT
                a.promotionid PromotionID,
                c.accountid AccountID,
                --CONVERT( VARCHAR(10), SAPAccountNumber) AS 'CustomerNumber'
			 SAPAccountNumber AS 'CustomerNumber'
         FROM #ValidPromotions a
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
                 FROM #IORoute WITH (NOLOCK)
             )
         )  --Getting promotions/account mapping for those account only which are in this routes)

         UNION
         SELECT DISTINCT
                a.promotionid,
                c.accountid,
                --CONVERT( VARCHAR(10), SAPAccountNumber) AS 'CustomerNumber'
			  SAPAccountNumber AS 'CustomerNumber'
         FROM #ValidPromotions a
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
                 FROM #IORoute WITH (NOLOCK)
             )
         );  --Getting promotions/account mapping for those account only which are in this routes)

         IF OBJECT_ID('tempdb..#Promotions') IS NOT NULL
             DROP TABLE #Promotions;
         IF OBJECT_ID('tempdb..#ValidPromotions') IS NOT NULL
             DROP TABLE #ValidPromotions;
         IF OBJECT_ID('tempdb..#PromotionStatus') IS NOT NULL
             DROP TABLE #PromotionStatus;
         IF OBJECT_ID('tempdb..#IORoute') IS NOT NULL
             DROP TABLE #IORoute;
     END;

GO

-----------------------------------------------
-----------------------------------------------
-----------------------------------------------

/****** Object:  StoredProcedure [Playbook].[pSaveDSDPromotion]    Script Date: 3/10/2017 11:32:58 AM ******/
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

	Commit Transaction

	If (@Debug = 1)
	Begin
		Select '---- Commiting done. That''s it ----' Debug, replace(convert(varchar(128), cast(DateDiff(MICROSECOND, @StartTime, SysDateTime()) as money), 1), '.00', '') TimeOffSetInMicroSeconds
		Select * 
		From PreCal.PromotionBranchChainGroup
		Where PromotionID = @PromotionID
	End

End



GO


