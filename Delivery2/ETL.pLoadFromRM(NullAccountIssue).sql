USE [Portal_Data]
GO
/****** Object:  StoredProcedure [ETL].[pLoadFromRM]    Script Date: 3/23/2017 2:40:10 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [ETL].[pLoadFromRM]
AS
--- ======================================================================================
--- Change Log (Most recent on top):
--- Date       INIT  Change Descrition
--- ---------- ----- ---------------------------------------------------------------------
--- 2016-08-02 KTY - SAP.Account - Fixed merge conditions within 'AND NOT'
--- ======================================================================================
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--------------------------------------------------------
	---Package----------------------------------------------
	DECLARE @sappk TABLE (
		PackageID INT
		,RMPackageID VARCHAR(10)
		,PackageTypeID INT
		,PackageConfID INT
		,PackageName VARCHAR(50)
		,Source VARCHAR(50)
		,Active VARCHAR(50)
		,ChangeTrackNumber INT
		)

	INSERT @sappk
	SELECT PackageID
		,RMPackageID
		,PackageTypeID
		,PackageConfID
		,PackageName
		,Source
		,Active
		,ChangeTrackNumber
	FROM SAP.Package

	MERGE @sappk AS a
	USING (
		SELECT p.PACKAGEID
			,pt.PackageTypeID
			,pc.PackageConfID
			,Replace(Replace(dbo.udf_TitleCase(p.Description), 'Oz', 'OZ'), 'Ls', 'LS') PackageName
			,0 Active
			,Replace(Replace(dbo.udf_TitleCase(p.Description), 'Oz', 'OZ'), 'Ls', 'LS') SPPackageName
		FROM Staging.RMPackage p
		LEFT JOIN SAP.PackageType pt ON p.SAPPackageTypeID = pt.SAPPackageTypeID
		LEFT JOIN SAP.PackageConf pc ON p.SAPPackageConfigID = pc.SAPPackageConfID
		) AS input
		ON a.RMPackageID = input.PACKAGEID
	WHEN MATCHED
		THEN
			UPDATE
			SET PackageTypeID = input.PackageTypeID
				,PackageConfID = input.PackageConfID
				,PackageName = input.PackageName
				,Source = 'RouteManager'
	WHEN NOT MATCHED BY Source
		THEN
			UPDATE
			SET Active = 0
	WHEN NOT MATCHED BY Target
		THEN
			INSERT (
				[RMPackageID]
				,[PackageTypeID]
				,[PackageConfID]
				,[PackageName]
				,Source
				,Active
				)
			VALUES (
				PACKAGEID
				,PackageTypeID
				,PackageConfID
				,[PackageName]
				,'RouteManager'
				,Active
				);

	MERGE @sappk AS bu
	USING (
		SELECT DISTINCT Rtrim(mbp.PackTypeID) + Rtrim(mbp.PackConfID) PACKAGEID
			,Replace(Replace(Replace(dbo.udf_TitleCase(Rtrim(mbp.PackType) + ' ' + Rtrim(mbp.PackConf)), 'Oz', 'OZ'), 'Ls', 'LS'), 'pk', 'PK') PACKAGEName
			,pc.PackageConfID
			,pt.PackageTypeID
		FROM Staging.MaterialBrandPKG mbp
		JOIN SAP.PackageConf pc ON mbp.PackConfID = pc.SAPPackageConfID
		JOIN SAP.PackageType pt ON mbp.PackTypeID = pt.SAPPackageTypeID
		) AS input
		ON bu.RMPackageID = input.PACKAGEID
	WHEN MATCHED
		THEN
			UPDATE
			SET bu.Active = 1
	WHEN NOT MATCHED BY Source
		THEN
			UPDATE
			SET bu.Active = 0
	WHEN NOT MATCHED BY Target
		THEN
			INSERT (
				[RMPackageID]
				,[PackageTypeID]
				,[PackageConfID]
				,[PackageName]
				,Active
				,Source
				)
			VALUES (
				PACKAGEID
				,PackageTypeID
				,PackageConfID
				,CASE 
					WHEN [PackageName] = 'Not Assigned Not Assigned'
						THEN 'Not Assigned'
					ELSE PackageName
					END
				,1
				,'SAPBW'
				);

	UPDATE @sappk
	SET ChangeTrackNumber = CHECKSUM(RMPackageID, PackageTypeID, PackageConfID, PackageName, Source, Active)

	MERGE SAP.Package AS pc
	USING @sappk AS input
		ON pc.PackageID = input.PackageID
	WHEN NOT MATCHED BY Target
		THEN
			INSERT (
				RMPackageID
				,PackageTypeID
				,PackageConfID
				,PackageName
				,Source
				,Active
				,ChangeTrackNumber
				,LastModified
				)
			VALUES (
				input.RMPackageID
				,input.PackageTypeID
				,input.PackageConfID
				,input.PackageName
				,input.Source
				,input.Active
				,input.ChangeTrackNumber
				,GetDate()
				);

	UPDATE sdm
	SET RMPackageID = sap.RMPackageID
		,PackageTypeID = sap.PackageTypeID
		,PackageConfID = sap.PackageConfID
		,PackageName = sap.PackageName
		,Source = sap.Source
		,Active = sap.Active
		,FriendlyName = sap.PackageName
		,ChangeTrackNumber = sap.ChangeTrackNumber
		,LastModified = GetDate()
	FROM @sappk sap
	JOIN SAP.Package sdm ON sap.PackageID = sdm.PackageID
		AND sap.ChangeTrackNumber != isnull(sdm.ChangeTrackNumber, 0)

	--------------------------------------------
	---- Account -------------------------------

	-- Merge From BW records
	MERGE SAP.Account AS a
	USING (
		SELECT
             CUSTOMER_NUMBER
			,max(CUSTOMER_NAME) CUSTOMER_NAME
			,max(CUSTOMER_STREET) CUSTOMER_STREET
			,max(CITY) CITY
			,max(STATE) STATE
			,max(POSTAL_CODE) POSTAL_CODE
			,max(CONTACT_PERSON) CONTACT_PERSON
			,max(PHONE_NUMBER) PHONE_NUMBER
			,max(BranchID) BranchID
			,max(ChannelID) ChannelID
			,max(LocalChainID) LocalChainID
		FROM (
			SELECT
                 convert(BIGINT, CUSTOMER_NUMBER) CUSTOMER_NUMBER
				,CUSTOMER_NAME
				,CUSTOMER_STREET
				,a.CITY
				,a.STATE
				,POSTAL_CODE
				,CONTACT_PERSON
				,PHONE_NUMBER
				,b.BranchID
				,c.ChannelID
				,lc.LocalChainID
			FROM Staging.BWAccount a
			LEFT JOIN Staging.AccountDetails ad ON  ISNUMERIC(ad.SAPAccountNumber) = 1
				                                AND convert(BIGINT, a.CUSTOMER_NUMBER) = convert(BIGINT, ad.SAPAccountNumber)
			LEFT JOIN SAP.Branch     b  ON b.SAPBranchID   = ad.SAPBranchID
			LEFT JOIN SAP.CHANNEL    c  ON ad.SAPChannelID = c.SAPChannelID
			LEFT JOIN SAP.LocalChain lc ON Right(ad.SAPLocalChainID, 7) = lc.SAPLocalChainID
			) tmp
		GROUP BY CUSTOMER_NUMBER
/*
Warning: Null value is eliminated by an aggregate or other SET operation.
(1150469 row(s) affected)
*/
		) AS input
		--USING (Select convert(bigint, CUSTOMER_NUMBER) CUSTOMER_NUMBER, CUSTOMER_NAME, CUSTOMER_STREET, CITY, STATE, POSTAL_CODE,
		--			CONTACT_PERSON, PHONE_NUMBER, b.BranchID, c.ChannelID, lc.LocalChainID
		--		From Staging.BWAccount a
		--			Left Join Staging.AccountDetails ad on ISNUMERIC(ad.SAPAccountNumber) = 1 And convert(bigint, a.CUSTOMER_NUMBER) = convert(bigint, ad.SAPAccountNumber)
		--			Left Join SAP.Branch b on b.SAPBranchID = ad.SAPBranchID
		--			Left Join SAP.CHANNEL c on ad.SAPChannelID = c.SAPChannelID
		--			Left Join SAP.LocalChain lc on Right(ad.SAPLocalChainID, 7) = lc.SAPLocalChainID
		--	  ) AS input
		ON a.SAPAccountNumber = input.CUSTOMER_NUMBER 
	WHEN MATCHED
        --- 2016-08-02 KTY - SAP.Account - Fixed merge conditions within 'AND NOT'
        AND NOT (
			    isnull(a.[AccountName] , '') = isnull(Case When isnull(InCapstone, 0) = 0 Then dbo.udf_TitleCase(input.CUSTOMER_NAME) Else [AccountName] End, '')
			AND isnull(a.[ChannelID]   , -1) = isnull(Case When isnull(InCapstone, 0) = 0 Then input.ChannelID Else a.ChannelID End, -1)
			AND isnull(a.[BranchID]    , -1) = isnull(input.BranchID, -1)
			AND isnull(a.[LocalChainID], -1) = isnull(Case When isnull(InCapstone, 0) = 0 Then input.LocalChainID Else a.LocalChainID End, -1)
			AND isnull(a.[Address]     , '') = isnull(Case When isnull(InCapstone, 0) = 0 Then dbo.udf_TitleCase(input.CUSTOMER_STREET) Else a.Address End, '')
			AND isnull(a.[City]        , '') = isnull(Case When isnull(InCapstone, 0) = 0 Then dbo.udf_TitleCase(input.CITY) Else a.City End, '')
			AND isnull(a.[State]       , '') = isnull(Case When isnull(InCapstone, 0) = 0 Then input.STATE Else a.State End, '')
			AND isnull(a.[PostalCode]  , '') = isnull(Case When isnull(InCapstone, 0) = 0 Then input.POSTAL_CODE Else a.PostalCode End, '')
			AND isnull(a.[Contact]     , '') = isnull(dbo.udf_TitleCase(input.CONTACT_PERSON), '')
			AND isnull(a.[PhoneNumber] , '') = isnull(Case When isnull(InCapstone, 0) = 0 Then input.PHONE_NUMBER Else a.PhoneNumber End, '')
            )
		THEN
			UPDATE
			--- BranchID, Active, Contact  always in ---
			SET  [AccountName]  = Case When isnull(InCapstone, 0) = 0 Then dbo.udf_TitleCase(input.CUSTOMER_NAME) Else [AccountName] End
				,[ChannelID]    = Case When isnull(InCapstone, 0) = 0 Then input.ChannelID Else a.ChannelID End
				,[BranchID]     = input.BranchID
				,[LocalChainID] = Case When isnull(InCapstone, 0) = 0 Then input.LocalChainID Else a.LocalChainID End
				,[Address]      = Case When isnull(InCapstone, 0) = 0 Then dbo.udf_TitleCase(input.CUSTOMER_STREET) Else a.Address End
				,[City]         = Case When isnull(InCapstone, 0) = 0 Then dbo.udf_TitleCase(input.CITY) Else a.City End
				,[State]        = Case When isnull(InCapstone, 0) = 0 Then input.STATE Else a.State End
				,[PostalCode]   = Case When isnull(InCapstone, 0) = 0 Then input.POSTAL_CODE Else a.PostalCode End
				,[Contact]      = dbo.udf_TitleCase(input.CONTACT_PERSON)
				,[PhoneNumber]  = Case When isnull(InCapstone, 0) = 0 Then input.PHONE_NUMBER Else a.PhoneNumber End
				,InBW           = 1
				,LastModified   = GetDate()
	WHEN NOT MATCHED BY Target
		THEN
			INSERT (
				 SAPAccountNumber
				,[AccountName]
				,[BranchID]
				,[Address]
				,[City]
				,[State]
				,[PostalCode]
				,[Contact]
				,[PhoneNumber]
				,ChannelID
				,LocalChainID
                ,InBW
				,LastModified  
				)
			VALUES (
				 CUSTOMER_NUMBER
				,dbo.udf_TitleCase(input.CUSTOMER_NAME)
				,BranchID
				,dbo.udf_TitleCase(CUSTOMER_STREET)
				,dbo.udf_TitleCase(CITY)
				,STATE
				,input.POSTAL_CODE
				,dbo.udf_TitleCase(CONTACT_PERSON)
				,PHONE_NUMBER
				,ChannelID
				,LocalChainID
                ,1 
				,GetDate()
				);

	-- Merge From RM records for Active Flag Only
	MERGE SAP.Account AS a
	USING (
		SELECT convert(BIGINT, CUSTOMER_NUMBER) CUSTOMER_NUMBER
			,a.ACTIVE
		FROM (
			SELECT
                 CUSTOMER_NUMBER
				,Max(ACTIVE) ACTIVE
			FROM Staging.RMAccount
			GROUP BY CUSTOMER_NUMBER
			) a
		) AS input
		ON a.SAPAccountNumber = input.CUSTOMER_NUMBER
	WHEN MATCHED AND Isnull(a.active, 0) <>  Isnull(input.ACTIVE, 0)
		THEN
			UPDATE
			SET ACTIVE = input.ACTIVE,
			LastModified = GetDate();

	-- We used to merge from RM as well(code commented)
	--MERGE SAP.Account AS a
	--USING (Select convert(bigint, CUSTOMER_NUMBER) CUSTOMER_NUMBER, CUSTOMER_NAME, CUSTOMER_STREET, CITY, STATE, POSTAL_CODE, a.ACTIVE, 
	--			CONTACT_PERSON, PHONE_NUMBER, b.BranchID, c.ChannelID, lc.LocalChainID
	--		From (Select CUSTOMER_NUMBER, Max(LOCATION_ID) LOCATION_ID, Max(CONTACT_PERSON) CONTACT_PERSON, Max(LOCAL_CHAIN) LOCAL_CHAIN, Max(CHANNEL) CHANNEL,
	--					Max(CUSTOMER_NAME) CUSTOMER_NAME, Max(CUSTOMER_STREET) CUSTOMER_STREET, Max(CITY) CITY, Max(STATE) STATE, Max(POSTAL_CODE) POSTAL_CODE,
	--					Max(PHONE_NUMBER) PHONE_NUMBER, Max(ACTIVE) ACTIVE
	--				From Staging.RMAccount 
	--				Group By CUSTOMER_NUMBER) a
	--				Left Join SAP.Branch b on Left(LOCATION_ID, 4) = b.SAPBranchID
	--				Left Join SAP.CHANNEL c on a.CHANNEL = c.SAPChannelID
	--				Left Join SAP.LocalChain lc on a.LOCAL_CHAIN = lc.SAPLocalChainID
	--	  ) AS input
	--	ON a.SAPAccountNumber = input.CUSTOMER_NUMBER
	--WHEN MATCHED THEN 
	--	UPDATE SET ACTIVE = input.ACTIVE
	--	  ,[AccountName] = dbo.udf_TitleCase(input.CUSTOMER_NAME)
	--	  ,[ChannelID] = input.ChannelID
	--	  ,[BranchID] = input.BranchID
	--	  ,[LocalChainID] = input.LocalChainID
	--	  ,[Address] = dbo.udf_TitleCase(input.CUSTOMER_STREET)
	--	  ,[City] = dbo.udf_TitleCase(input.CITY)
	--	  ,[State] = input.STATE
	--	  ,[PostalCode] = input.POSTAL_CODE
	--	  ,[Contact] = dbo.udf_TitleCase(input.CONTACT_PERSON)
	--	  ,[PhoneNumber] = input.PHONE_NUMBER
	--WHEN NOT MATCHED By Target THEN
	--	INSERT (SAPAccountNumber
	--		   ,[AccountName]
	--		   ,[BranchID]
	--		   ,[Address]
	--		   ,[City]
	--		   ,[State]
	--		   ,[PostalCode]
	--		   ,[Contact]
	--		   ,[PhoneNumber]
	--		   ,ACTIVE
	--		   ,ChannelID
	--		   ,LocalChainID
	--		   )
	--	 VALUES
	--		   (CUSTOMER_NUMBER
	--		   ,dbo.udf_TitleCase(input.CUSTOMER_NAME)
	--		   ,BranchID
	--		   ,dbo.udf_TitleCase(CUSTOMER_STREET)
	--		   ,dbo.udf_TitleCase(CITY)
	--		   ,STATE
	--		   ,input.POSTAL_CODE
	--		   ,dbo.udf_TitleCase(CONTACT_PERSON)
	--		   ,PHONE_NUMBER
	--		   ,ACTIVE
	--		   ,ChannelID
	--		   ,LocalChainID);

	--- Accounts Geo from RoadNet
	UPDATE acc
	SET acc.Longitude = rnl.LONGITUDE
		,acc.Latitude = rnl.LATITUDE
		,GeoSource = 'RN'
		,GeoCodingNeeded = 0
	FROM (
		SELECT AccountNumber,
			LONGITUDE,
			LATITUDE,
			SalesOffice
		FROM Staging.RNLocation
		WHERE ISNUMERIC(AccountNumber) = 1
		And   Charindex('.', AccountNumber) = 0
		) rnl
	JOIN SAP.Account acc ON rnl.AccountNumber = acc.SAPAccountNumber
	Join SAP.Branch b on acc.BranchID = b.BranchID
	Where b.SAPBranchID = rnl.SalesOffice
	And rnl.Longitude <> 0
	And isnull(acc.InCapstone, 0) = 0

	--- That's what BW only account cares about
	--- CHECKSUM( SAPAccountNumber, AccountName, ChannelID, BranchID, LocalChainID, 
	---           Address, City, STATE, PostalCode, Contact, PhoneNumber, Longitude, Latitude, Active)
	UPDATE SAP.Account
	SET ChangeTrackNumber = CHECKSUM(SAPAccountNumber, AccountName, ChannelID, BranchID, LocalChainID, Address, City, STATE, PostalCode, Contact, PhoneNumber, Longitude, Latitude, Active)
		,LastModified = GetDate(), StoreLastModified = GetDate()
	WHERE isnull(ChangeTrackNumber, 0) != CHECKSUM(SAPAccountNumber, AccountName, ChannelID, BranchID, LocalChainID, Address, City, STATE, PostalCode, Contact, PhoneNumber, Longitude, Latitude, Active)
	And IsNUll(InCapstone,0) = 0

	--------------------------------------------------
	---- Person.RMEmployee ---------------------------
	Declare @Count int

	Select @Count = Count(*) From Staging.RMEmployee
	
	If (@Count > 0)
	Begin
		MERGE Person.RMEmployee AS A --Target
	USING (
		SELECT EmployeeID
			,RoleID
			,dbo.udf_TitleCase(FirstName) FirstName
			,dbo.udf_TitleCase(LastName) LastName
			,BranchID
			,A.Active
			,GSN
		FROM Staging.RMEmployee A
			,SAP.Branch B
			,Person.ROLE C
		WHERE Left(A.Location_ID, 4) = B.SAPBranchID
			AND C.RoleName = A.JobRole
		) AS B --Source
		ON A.EmployeeID = B.EmployeeID
	WHEN MATCHED
		THEN
			UPDATE
			SET RoleID = B.RoleID
				,FirstName = B.FirstName
				,LastName = B.LastName
				,BranchID = B.BranchID
				,Active = B.Active
				,GSN = B.GSN
	WHEN NOT MATCHED BY Target
		THEN
			INSERT (
				EmployeeID
				,RoleID
				,FirstName
				,LastName
				,BranchID
				,Active
				,GSN
				)
			VALUES (
				B.EmployeeID
				,B.RoleID
				,B.FirstName
				,B.LastName
				,B.BranchID
				,B.Active
				,B.GSN
				);
    End

	--------------------------------------------------
	---- Route ----------------------------------
	Select @Count = Count(*) From Staging.RMROUTEMASTER
	
	If (@Count > 0)
	Begin
		MERGE SAP.Route AS r
	USING (
		SELECT ROUTE_NUMBER
			,ROUTE_DESCRIPTION
			,ACTIVE_ROUTE
			,ROUTE_TYPE
			,r.LOCATION_ID
			,DEFAULT_EMPLOYEE
			,b.BranchID
			,up.GSN
			,DISPLAYALLOWANCE
			,SALES_GROUP
		FROM Staging.RMROUTEMASTER r
		LEFT JOIN Staging.RMEmployee e ON r.Default_Employee = e.EmployeeID
		LEFT JOIN Person.UserProfile up ON e.GSN = up.GSN
		LEFT JOIN SAP.Branch b ON Left(r.LOCATION_ID, 4) = b.SAPBranchID
		WHERE r.Active = '1'
			--And r.Route_Type = '0'
			AND Active_Route = '1'
		) AS input
		ON r.SAPRouteNumber = input.ROUTE_NUMBER
	WHEN MATCHED
		THEN
			UPDATE
			SET SAPRouteNumber = input.ROUTE_NUMBER
				,[RouteName] = dbo.udf_TitleCase(input.ROUTE_DESCRIPTION)
				,[DefaultAccountManagerGSN] = input.GSN
				,BranchID = input.BranchID
				,EmployeeID = DEFAULT_EMPLOYEE
				,RouteTypeID = ROUTE_TYPE
				,Active = 1
				,DisplayAllowance = input.DISPLAYALLOWANCE
				,SalesGroup = SALES_GROUP
	WHEN NOT MATCHED BY Source
		THEN
			UPDATE
			SET Active = 0
	WHEN NOT MATCHED BY Target
		THEN
			INSERT (
				SAPRouteNumber
				,[RouteName]
				,BranchID
				,[Active]
				,[DefaultAccountManagerGSN]
				,EmployeeID
				,RouteTypeID
				,DisplayAllowance
				,SalesGroup
				)
			VALUES (
				input.ROUTE_NUMBER
				,dbo.udf_TitleCase(input.ROUTE_DESCRIPTION)
				,input.BranchID
				,1
				,input.GSN
				,DEFAULT_EMPLOYEE
				,input.ROUTE_TYPE
				,input.DISPLAYALLOWANCE
				,input.SALES_GROUP
				);
	End

	-----------------------------------------------------
	---- RouteSchedule ----------------------------------
	Select @Count = Count(*) From Staging.RMRouteSchedule

	If (@Count > 0)
	Begin	
		MERGE SAP.RouteSchedule AS bu
		USING (
			SELECT sr.RouteID
				,a.AccountID
				,START_Date
				,t.Route_Number
				,t.Customer_Number
			FROM [Staging].[RMRouteSchedule] t
			-- Inner joins to take only the active routes and active customers
			JOIN SAP.Route sr ON t.ROUTE_NUMBER = sr.SAPRouteNumber
			JOIN SAP.Account a ON t.CUSTOMER_NUMBER = a.SAPAccountNumber
			) AS input
			ON bu.RouteID = input.RouteID
				AND bu.AccountID = input.AccountID
		WHEN MATCHED
			THEN
				UPDATE
				SET bu.StartDate = input.Start_Date
		WHEN NOT MATCHED BY Target
			THEN
				INSERT (
					RouteID
					,AccountID
					,StartDate
					)
				VALUES (
					input.RouteID
					,input.AccountID
					,input.Start_Date
					)
		WHEN NOT MATCHED BY Source
			THEN
				DELETE;
	End
	-----------------------------------------------------------
	---- RouteScheduleDetail ----------------------------------
	If (@Count > 0)
	Begin
		TRUNCATE TABLE SAP.RouteScheduleDetail

		DECLARE @dayCounter INT
		DECLARE @indexStarter INT

		SET @indexStarter = 0
		SET @dayCounter = 0

		WHILE @dayCounter < 28
		BEGIN
		SET @indexStarter = 3 * @dayCounter + 1

		INSERT INTO SAP.RouteScheduleDetail (
			RouteScheduleID
			,Day
			,SequenceNumber
			)
		SELECT saprs.RouteScheduleID
			,@dayCounter
			,Convert(INT, substring(SEQUENCE_NUMBER, @indexStarter, 3)) AS SEQUENCE_NUMBER
		FROM [Staging].[RMRouteSchedule] t
		JOIN SAP.Route sr ON t.ROUTE_NUMBER = sr.SAPRouteNumber
		JOIN SAP.Account a ON t.CUSTOMER_NUMBER = a.SAPAccountNumber
		JOIN SAP.RouteSchedule saprs ON saprs.AccountID = a.AccountID
			AND saprs.RouteID = sr.RouteID
		WHERE Convert(INT, substring(SEQUENCE_NUMBER, @indexStarter, 3)) > 0;

		SET @dayCounter = @dayCounter + 1;
	END
	End
END

exec [ETL].[pLoadFromRM]
Go