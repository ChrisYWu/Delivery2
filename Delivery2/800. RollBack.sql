USE [Portal_Data]
GO

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

